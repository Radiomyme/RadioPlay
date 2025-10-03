//
//  AudioPlayerService.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

//
//  AudioPlayerService corrigé (erreur Optional)
//  RadioPlay
//

//
//  AudioPlayerService (version sans binding)
//  RadioPlay
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

            // Définir la catégorie AVAudioSession
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .mixWithOthers]
            )

            // Définir la priorité audio élevée
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
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

            // On conserve isPlaying à true pour savoir qu'il faudra reprendre

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
        let url = URL(string: streamURL)!

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

        // Créer un AVAsset avec des options réseau optimisées
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "RadioPlay/1.0"]
        ])

        playerItem = AVPlayerItem(asset: asset)

        // Observer l'état de préparation de l'item
        statusObserver = playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
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

                // Tentative de récupération si possible
                if self.isPlaying {
                    self.needsRestart = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if self.needsRestart, let station = self.currentStation {
                            print("🔄 Tentative de reprise après échec")
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

        // Créer le player avec un comportement optimisé pour le streaming
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.volume = 1.0

        // Configurer les observateurs pour les métadonnées
        setupMetadataObservers()

        // Configurer l'observateur de lecture
        setupPlaybackObserver()

        // Démarrer la lecture avec un léger délai pour assurer la stabilité
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.player?.play()
            self.isPlaying = true
            print("▶️ Lecture démarrée: \(station.name)")

            // Initialiser les métadonnées par défaut
            self.currentTrack = Track(title: station.subtitle, artist: station.name, album: nil)
            self.updateNowPlayingInfo()
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
        // Ne pas réinitialiser currentStation pour permettre la reprise

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

        // Ajouter un nouvel observateur périodique
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
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
        let cleanTitle = streamTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // Liste de titres invalides à ignorer
        let invalidTitles = ["true", "false", "null", "unknown", "n/a", "-", ""]

        // Vérifier si c'est un titre invalide
        guard !invalidTitles.contains(cleanTitle.lowercased()) else {
            // Ne pas mettre à jour currentTrack si le titre est invalide
            return
        }

        let components = cleanTitle.components(separatedBy: " - ")

        if components.count >= 2 {
            let artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

            // Vérifier que l'artiste et le titre ne sont pas vides ou invalides
            guard !artist.isEmpty && !title.isEmpty &&
                  !invalidTitles.contains(artist.lowercased()) &&
                  !invalidTitles.contains(title.lowercased()) else {
                return
            }

            currentTrack = Track(title: title, artist: artist, album: nil)
        } else if cleanTitle.count > 3 { // Au moins 3 caractères pour être valide
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
        guard let track = currentTrack else { return }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist

        if let album = track.album {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        }

        // Ajouter des informations de contrôle
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true

        // Ajouter l'artwork si disponible
        if let station = currentStation,
           let logoURLString = station.logoURL,
           !logoURLString.isEmpty,
           let logoURL = URL(string: logoURLString) {
            DispatchQueue.global(qos: .utility).async {
                do {
                    let imageData = try Data(contentsOf: logoURL)
                    if let image = UIImage(data: imageData) {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }

                        DispatchQueue.main.async {
                            var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                            updatedInfo[MPMediaItemPropertyArtwork] = artwork
                            MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                        }
                    }
                } catch {
                    print("Impossible de charger l'artwork: \(error)")
                }
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    deinit {
        // Nettoyage des observateurs
        NotificationCenter.default.removeObserver(self)

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
