//
//  AudioPlayerService.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Domain/Services/AudioPlayerService.swift
import Foundation
import AVFoundation
import MediaPlayer

class AudioPlayerService: NSObject, ObservableObject, AVPlayerItemMetadataOutputPushDelegate {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isBuffering = false

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var metadataOutput: AVPlayerItemMetadataOutput?

    override init() {
        super.init()
        setupAudioSession()
        setupRemoteTransportControls()
    }

    // Implémentation du protocole AVPlayerItemMetadataOutputPushDelegate
    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        if let group = groups.first,
           let metadataItem = group.items.first,
           let value = metadataItem.value as? String {
            parseStreamTitle(value)
        }
    }

    func play(station: Station) {
        guard let url = URL(string: station.streamURL) else { return }
        
        isBuffering = true
        
        // Créer l'item pour le player
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = false

        // Observer pour les métadonnées (Icecast, Shoutcast)
        setupMetadataObservers()
        
        // Observer pour l'état de buffering
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.new], context: nil)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: [.new], context: nil)
        
        // Démarrer la lecture
        player?.play()
        isPlaying = true
        
        // Mettre par défaut le titre de la station
        currentTrack = Track(title: station.subtitle, artist: station.name, album: nil)
        updateNowPlayingInfo()
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }
    
    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
        currentTrack = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Private methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Observer pour les interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    private func setupMetadataObservers() {
        // Observer pour les métadonnées AVPlayerItem
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMetadataUpdate),
            name: .AVPlayerItemNewAccessLogEntry,
            object: playerItem
        )

        // Configuration avancée pour les métadonnées
        metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput?.setDelegate(self, queue: DispatchQueue.main)
        playerItem?.add(metadataOutput!)
    }

    @objc private func handleMetadataUpdate(notification: Notification) {
        guard let playerItem = player?.currentItem else { return }
        
        // Essayer d'extraire les métadonnées ICY (format radio Internet courant)
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
        // Format typique: "Artiste - Titre"
        let components = streamTitle.components(separatedBy: " - ")
        
        if components.count >= 2 {
            let artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            currentTrack = Track(title: title, artist: artist, album: nil)
        } else {
            // Si le format n'est pas standard, utiliser tout comme titre
            currentTrack = Track(title: streamTitle, artist: "", album: nil)
        }
        
        updateNowPlayingInfo()
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption a commencé
            player?.pause()
            isPlaying = false
        case .ended:
            // Interruption terminée
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                player?.play()
                isPlaying = true
            }
        @unknown default:
            break
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            if let isBufferEmpty = change?[.newKey] as? Bool, isBufferEmpty {
                isBuffering = true
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            if let isLikelyToKeepUp = change?[.newKey] as? Bool, isLikelyToKeepUp {
                isBuffering = false
            }
        }
    }
    
    // MARK: - Remote control & Now Playing
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Commande Play
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            
            self.player?.play()
            self.isPlaying = true
            return .success
        }
        
        // Commande Pause
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            
            self.player?.pause()
            self.isPlaying = false
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
        
        // État de lecture
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
    }
}
