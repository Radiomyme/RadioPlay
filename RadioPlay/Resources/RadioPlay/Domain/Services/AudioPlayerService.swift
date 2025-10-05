//
//  AudioPlayerService.swift
//  RadioPlay
//
//  Created by Martin Parmentier.
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit

class AudioPlayerService: NSObject, ObservableObject, AVPlayerItemMetadataOutputPushDelegate {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isBuffering = false

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var metadataOutput: AVPlayerItemMetadataOutput?
    private var timeObserverToken: Any?
    private var statusObserver: NSKeyValueObservation?

    // Gestion avancée de l'audio en arrière-plan
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var isAudioSessionActive = false
    private var currentStation: Station?
    private var needsRestart = false

    override init() {
        super.init()
        // Initialisation proactive de l'audio
        setupAudioSession()
        setupBackgroundPlayback()
    }

    // MARK: - Configuration pour l'arrière-plan

    private func setupBackgroundPlayback() {
        // Configurer les contrôles à distance
        setupRemoteTransportControls()

        // Observateurs pour les transitions d'état de l'app
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        // Observer les interruptions audio
        notificationCenter.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        // Observer les changements de route audio
        notificationCenter.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    private func setupAudioSession() {
        print("Configuration de la session audio...")

        do {
            let audioSession = AVAudioSession.sharedInstance()

            // ✅ Configuration optimale pour streaming sans coupures
            // La policy .longFormAudio n'accepte AUCUNE option, donc on utilise .default
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .mixWithOthers]
            )

            // ✅ Buffer optimal pour streaming
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms - réduit la latence

            // ✅ Préférences pour la qualité audio
            try audioSession.setPreferredSampleRate(44100.0)

            // Activer la session avec priorité élevée
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            isAudioSessionActive = true

            print("✅ Session audio configurée avec succès")
        } catch {
            print("❌ Échec de la configuration de la session audio: \(error)")
            isAudioSessionActive = false
        }
    }

    // MARK: - Gestion des transitions de l'app

    @objc private func handleAppDidEnterBackground() {
        print("📱 Application entrée en arrière-plan")
        beginBackgroundTask()

        // S'assurer que la lecture continue en arrière-plan
        if isPlaying {
            ensurePlaybackContinues()
        }
    }

    @objc private func handleAppWillEnterForeground() {
        print("📱 Application revient au premier plan")
        endBackgroundTask()

        // Vérifier si la lecture a été interrompue en arrière-plan
        if isPlaying && player?.timeControlStatus != .playing {
            print("Reprise de la lecture interrompue")
            player?.play()
        }

        // Si une station était en lecture mais a été interrompue
        if needsRestart, let station = currentStation {
            needsRestart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.play(station: station)
            }
        }

        // Force le rafraîchissement de l'interface
        objectWillChange.send()
    }

    @objc private func handleAppWillTerminate() {
        print("📱 Application en cours de fermeture")
        endBackgroundTask()
    }

    // MARK: - Gestion des tâches d'arrière-plan

    private func beginBackgroundTask() {
        endBackgroundTask() // Terminer toute tâche existante

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("⏱️ Expiration du temps d'arrière-plan")
            self?.endBackgroundTask()
        }

        print("⏱️ Tâche d'arrière-plan commencée: \(backgroundTask)")
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            print("⏱️ Tâche d'arrière-plan terminée")
        }
    }

    private func ensurePlaybackContinues() {
        if !isAudioSessionActive {
            print("Réactivation de la session audio...")
            setupAudioSession()
        }

        if let player = player {
            if player.timeControlStatus != .playing && isPlaying {
                print("🔄 Relance de la lecture en arrière-plan")
                player.play()
            }
        } else if isPlaying, let station = currentStation {
            // Le player a été détruit, mais on devrait être en lecture
            needsRestart = true
            print("⚠️ Le player a été détruit alors qu'il devrait être en lecture")
        }
    }

    // MARK: - Gestion des événements système

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            print("🔇 Interruption audio commencée")
            player?.pause()
            isAudioSessionActive = false

        case .ended:
            print("🔈 Interruption audio terminée")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {

                // Réactiver la session audio
                setupAudioSession()

                // Reprendre la lecture si c'était le cas avant l'interruption
                if isPlaying {
                    player?.play()
                    print("▶️ Lecture reprise après interruption")
                }
            }

        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .newDeviceAvailable:
            print("🎧 Nouveau périphérique audio connecté")

        case .oldDeviceUnavailable:
            print("🔌 Périphérique audio déconnecté")

        case .categoryChange:
            print("🔄 Catégorie audio changée")
            if isPlaying {
                ensurePlaybackContinues()
            }

        default:
            break
        }
    }

    // MARK: - Commandes de lecture

    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        if let group = groups.first,
           let metadataItem = group.items.first,
           let value = metadataItem.value as? String {
            parseStreamTitle(value)
        }
    }

    func play(station: Station) {
        let streamURL = station.streamURL
        guard let url = URL(string: streamURL) else {
            print("❌ URL invalide: \(streamURL)")
            return
        }

        // Stocker la station en cours pour pouvoir reprendre si nécessaire
        currentStation = station

        // Arrêter toute lecture précédente
        stop()

        // S'assurer que la session audio est active
        if !isAudioSessionActive {
            setupAudioSession()
        }

        // Démarrer une tâche d'arrière-plan
        beginBackgroundTask()

        print("⏳ Préparation de la lecture pour: \(station.name)")
        isBuffering = true

        // ✅ Créer un AVAsset avec options réseau optimisées pour réduire les coupures
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "User-Agent": "RadioPlay/1.0",
                "Icy-MetaData": "1"
            ],
            AVURLAssetPreferPreciseDurationAndTimingKey: false,
            AVURLAssetHTTPCookiesKey: [] as [HTTPCookie]
        ])

        // ✅ Utiliser l'API moderne pour iOS 15+
        Task {
            do {
                // Charger l'asset de manière asynchrone (iOS 15+)
                let isPlayable = try await asset.load(.isPlayable)

                guard isPlayable else {
                    await MainActor.run {
                        print("❌ Asset non jouable")
                        self.isBuffering = false
                    }
                    return
                }

                await MainActor.run {
                    // Créer le playerItem
                    self.playerItem = AVPlayerItem(asset: asset)

                    // ✅ Configuration optimale du buffer
                    self.playerItem?.preferredForwardBufferDuration = 15.0 // 15 secondes de buffer
                    self.playerItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true

                    // Observer l'état de préparation de l'item
                    self.statusObserver = self.playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
                        guard let self = self else { return }

                        switch item.status {
                        case .readyToPlay:
                            print("✅ Flux prêt à être lu")
                            self.isBuffering = false

                            // Démarrer la lecture si nécessaire
                            if self.isPlaying && self.player?.rate == 0 {
                                self.player?.play()
                            }

                        case .failed:
                            print("❌ Échec de préparation du flux: \(String(describing: item.error))")
                            self.isBuffering = false

                            // Tentative de récupération
                            if self.isPlaying {
                                self.needsRestart = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    if self.needsRestart, let station = self.currentStation {
                                        print("🔄 Tentative de reprise après échec")
                                        self.needsRestart = false
                                        self.play(station: station)
                                    }
                                }
                            }

                        case .unknown:
                            break

                        @unknown default:
                            break
                        }
                    }

                    // Créer le player avec configuration optimisée
                    self.player = AVPlayer(playerItem: self.playerItem)

                    // ✅ Configuration optimale pour le streaming en continu
                    self.player?.automaticallyWaitsToMinimizeStalling = true
                    self.player?.volume = 1.0

                    // ✅ Configuration pour iOS 16+
                    if #available(iOS 16.0, *) {
                        self.player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
                        self.player?.preventsDisplaySleepDuringVideoPlayback = false
                    }

                    // ✅ Activer l'option de lecture en arrière-plan
                    self.player?.allowsExternalPlayback = true

                    // Configurer les observateurs
                    self.setupMetadataObservers()
                    self.setupPlaybackObserver()
                    self.setupBufferObservers()

                    // Démarrer la lecture après un court délai
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.player?.play()
                        self.isPlaying = true
                        print("▶️ Lecture démarrée: \(station.name)")

                        // Initialiser les métadonnées par défaut
                        self.currentTrack = Track(title: station.subtitle, artist: station.name, album: nil)
                        self.updateNowPlayingInfo()
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Erreur lors du chargement de l'asset: \(error)")
                    self.isBuffering = false
                }
            }
        }
    }

    func togglePlayPause() {
        if isPlaying {
            print("⏸ Mise en pause")
            player?.pause()
            isPlaying = false

            // On garde la tâche d'arrière-plan un moment même après la pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if !self.isPlaying {
                    self.endBackgroundTask()
                }
            }
        } else {
            print("▶️ Reprise de la lecture")

            // Réactiver la session si nécessaire
            if !isAudioSessionActive {
                setupAudioSession()
            }

            // Démarrer une tâche d'arrière-plan
            beginBackgroundTask()

            // Si le player existe, reprendre la lecture
            if let player = player {
                player.play()
                isPlaying = true
            } else if let station = currentStation {
                // Sinon, redémarrer la lecture
                play(station: station)
            }
        }

        // Mise à jour du centre de contrôle
        updateNowPlayingInfo()
    }

    func stop() {
        print("⏹ Arrêt de la lecture")

        // Nettoyage des observateurs KVO
        if let item = playerItem {
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackBufferFull")
        }

        // Nettoyage des observateurs
        statusObserver?.invalidate()
        statusObserver = nil

        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        // Arrêt du player
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil

        // Mise à jour de l'état
        isPlaying = false
        isBuffering = false
        needsRestart = false

        // Nettoyage des infos de lecture
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        // Fin de la tâche d'arrière-plan (avec délai pour éviter les coupures)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.endBackgroundTask()
        }
    }

    // MARK: - Observateurs et métadonnées

    private func setupPlaybackObserver() {
        // Supprimer l'observateur existant
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        // ✅ Réduire la fréquence de vérification pour économiser les ressources
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 2.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }

            // Vérifier seulement si on est supposé être en lecture
            if self.isPlaying {
                // Vérifier si la lecture est en pause mais devrait être active
                if let player = self.player, player.timeControlStatus == .paused && !self.isBuffering {
                    print("🔄 Reprise de la lecture en pause")
                    player.play()
                }

                // Vérifier si la session audio est active
                if !self.isAudioSessionActive {
                    print("🔄 Réactivation de la session audio")
                    self.setupAudioSession()
                }
            }
        }

        // ✅ NOUVEAU - Observer les événements de stalling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStalled),
            name: .AVPlayerItemPlaybackStalled,
            object: playerItem
        )
    }

    // ✅ NOUVEAU - Gérer les événements de buffering
    @objc private func handlePlaybackStalled(notification: Notification) {
        print("⚠️ Buffering détecté...")
        isBuffering = true

        // Attendre un peu puis reprendre
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            if self.isPlaying && self.player?.timeControlStatus != .playing {
                print("🔄 Reprise après buffering")
                self.player?.play()
            }

            self.isBuffering = false
        }
    }

    // ✅ NOUVEAU - Observer l'état du buffer
    private func setupBufferObservers() {
        guard let playerItem = playerItem else { return }

        // Observer l'état du buffer
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new], context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.new], context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackBufferFull", options: [.new], context: nil)
    }

    // ✅ Observer les changements du buffer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }

        switch keyPath {
        case "playbackLikelyToKeepUp":
            if item.isPlaybackLikelyToKeepUp {
                print("✅ Buffer suffisant pour lecture continue")
                isBuffering = false
                if isPlaying && player?.rate == 0 {
                    player?.play()
                }
            }

        case "playbackBufferEmpty":
            if item.isPlaybackBufferEmpty {
                print("⚠️ Buffer vide - buffering en cours")
                isBuffering = true
            }

        case "playbackBufferFull":
            if item.isPlaybackBufferFull {
                print("✅ Buffer plein")
            }

        default:
            break
        }
    }

    private func setupMetadataObservers() {
        // Observer les métadonnées du flux
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMetadataUpdate),
            name: .AVPlayerItemNewAccessLogEntry,
            object: playerItem
        )

        // Configuration du délégué pour les métadonnées
        metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput?.setDelegate(self, queue: DispatchQueue.main)
        playerItem?.add(metadataOutput!)
    }

    @objc private func handleMetadataUpdate(notification: Notification) {
        guard let playerItem = player?.currentItem else { return }

        if let metadataList = playerItem.timedMetadata {
            for item in metadataList {
                if let streamTitle = item.value as? String {
                    parseStreamTitle(streamTitle)
                    break
                }
            }
        }
    }

    private func parseStreamTitle(_ streamTitle: String) {
        // Nettoyer et valider le titre
        var cleanTitle = streamTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // ✅ Nettoyer les caractères parasites (§, numéros, etc.)
        if let sectionIndex = cleanTitle.firstIndex(of: "§") {
            cleanTitle = String(cleanTitle[..<sectionIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Supprimer les séquences de chiffres de plus de 5 caractères consécutifs
        cleanTitle = cleanTitle.replacingOccurrences(
            of: "\\s*\\d{6,}\\s*",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        // Nettoyer les espaces multiples
        cleanTitle = cleanTitle.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        // Liste de titres invalides à ignorer
        let invalidTitles = ["true", "false", "null", "unknown", "n/a", "-", ""]

        // Vérifier si c'est un titre invalide
        guard !invalidTitles.contains(cleanTitle.lowercased()) else {
            return
        }

        let components = cleanTitle.components(separatedBy: " - ")

        if components.count >= 2 {
            var artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            var title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

            // ✅ Nettoyer aussi l'artiste et le titre individuellement
            if let sectionIndex = artist.firstIndex(of: "§") {
                artist = String(artist[..<sectionIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let sectionIndex = title.firstIndex(of: "§") {
                title = String(title[..<sectionIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Vérifier que l'artiste et le titre ne sont pas vides ou invalides
            guard !artist.isEmpty && !title.isEmpty &&
                  !invalidTitles.contains(artist.lowercased()) &&
                  !invalidTitles.contains(title.lowercased()) else {
                return
            }

            currentTrack = Track(title: title, artist: artist, album: nil)
        } else if cleanTitle.count > 3 {
            currentTrack = Track(title: cleanTitle, artist: "", album: nil)
        }

        // Mise à jour des infos du centre de contrôle
        updateNowPlayingInfo()

        // Notification pour l'interface
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // MARK: - Contrôles à distance

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Nettoyer les anciennes cibles
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)

        // Commande lecture
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if !self.isPlaying {
                if !self.isAudioSessionActive {
                    self.setupAudioSession()
                }

                self.beginBackgroundTask()

                if let player = self.player {
                    player.play()
                    self.isPlaying = true
                    return .success
                } else if let station = self.currentStation {
                    self.play(station: station)
                    return .success
                }
            }

            return .commandFailed
        }

        // Commande pause
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if self.isPlaying {
                self.player?.pause()
                self.isPlaying = false
                return .success
            }

            return .commandFailed
        }

        // Commande toggle
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            self.togglePlayPause()
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let station = currentStation else { return }

        var nowPlayingInfo = [String: Any]()

        // ✅ Titre et artiste
        if let track = currentTrack, !track.title.isEmpty {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist.isEmpty ? station.name : track.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = station.subtitle
        } else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = station.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = station.subtitle
        }

        // ✅ Type de contenu - Live Stream
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true

        // ✅ État de lecture
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0

        // ✅ Durée (pour live stream, on met des valeurs indéfinies)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0

        // ✅ Type de média
        nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.anyAudio.rawValue

        // Mettre à jour immédiatement avec ces infos
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        // ✅ Charger l'artwork de manière asynchrone
        loadArtworkForNowPlaying(station: station, baseInfo: nowPlayingInfo)
    }

    // ✅ NOUVEAU - Charger l'artwork pour le Now Playing
    private func loadArtworkForNowPlaying(station: Station, baseInfo: [String: Any]) {
        // Essayer d'abord l'artwork de la piste si disponible
        if let track = currentTrack, !track.title.isEmpty {
            loadTrackArtwork(track: track, station: station, baseInfo: baseInfo)
        } else {
            // Sinon charger directement le logo de la station
            loadStationArtwork(station: station, baseInfo: baseInfo)
        }
    }

    // ✅ Charger l'artwork de la piste depuis iTunes
    private func loadTrackArtwork(track: Track, station: Station, baseInfo: [String: Any]) {
        let query = "\(track.artist) \(track.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(query)&entity=song&limit=1"

        guard let url = URL(string: urlString) else {
            loadStationArtwork(station: station, baseInfo: baseInfo)
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)

                if let firstResult = result.results.first,
                   let artworkURLString = firstResult.artworkUrl100?.replacingOccurrences(of: "100x100", with: "600x600"),
                   let artworkURL = URL(string: artworkURLString) {

                    let (imageData, _) = try await URLSession.shared.data(from: artworkURL)
                    if let image = UIImage(data: imageData) {
                        await updateNowPlayingArtwork(image: image, baseInfo: baseInfo)
                        return
                    }
                }

                // Si pas d'artwork trouvé, utiliser le logo de la station
                await MainActor.run {
                    self.loadStationArtwork(station: station, baseInfo: baseInfo)
                }
            } catch {
                print("Erreur lors du chargement de l'artwork iTunes: \(error)")
                await MainActor.run {
                    self.loadStationArtwork(station: station, baseInfo: baseInfo)
                }
            }
        }
    }

    // ✅ Charger le logo de la station
    private func loadStationArtwork(station: Station, baseInfo: [String: Any]) {
        guard let logoURLString = station.logoURL,
              !logoURLString.isEmpty,
              let logoURL = URL(string: logoURLString) else {
            // Utiliser l'image par défaut
            if let defaultImage = UIImage(named: "default_artwork") {
                updateNowPlayingArtworkSync(image: defaultImage, baseInfo: baseInfo)
            }
            return
        }

        Task {
            do {
                let (imageData, _) = try await URLSession.shared.data(from: logoURL)
                if let image = UIImage(data: imageData) {
                    await updateNowPlayingArtwork(image: image, baseInfo: baseInfo)
                } else if let defaultImage = UIImage(named: "default_artwork") {
                    await updateNowPlayingArtwork(image: defaultImage, baseInfo: baseInfo)
                }
            } catch {
                print("Erreur lors du chargement du logo: \(error)")
                if let defaultImage = UIImage(named: "default_artwork") {
                    await updateNowPlayingArtwork(image: defaultImage, baseInfo: baseInfo)
                }
            }
        }
    }

    // ✅ Mettre à jour l'artwork dans le Now Playing (async)
    private func updateNowPlayingArtwork(image: UIImage, baseInfo: [String: Any]) async {
        await MainActor.run {
            updateNowPlayingArtworkSync(image: image, baseInfo: baseInfo)
        }
    }

    // ✅ Mettre à jour l'artwork dans le Now Playing (sync)
    private func updateNowPlayingArtworkSync(image: UIImage, baseInfo: [String: Any]) {
        var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? baseInfo

        // Créer l'artwork pour le lock screen
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
            return image
        }

        updatedInfo[MPMediaItemPropertyArtwork] = artwork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo

        print("✅ Now Playing Info mis à jour avec artwork")
    }

    deinit {
        // Nettoyage des observateurs
        NotificationCenter.default.removeObserver(self)

        // Nettoyage des observateurs KVO
        if let item = playerItem {
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackBufferFull")
        }

        statusObserver?.invalidate()

        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }

        // Fin de la tâche d'arrière-plan
        endBackgroundTask()

        // Désactiver la session audio
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Erreur lors de la désactivation de la session audio: \(error)")
        }
    }
}
