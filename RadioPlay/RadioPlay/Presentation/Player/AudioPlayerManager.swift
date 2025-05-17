//
//  AudioPlayerManager.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import Foundation
import UIKit
import Combine
import MediaPlayer

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()
    
    private let audioService = AudioPlayerService()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentStation: Station?
    @Published var isPlaying: Bool = false
    @Published var currentTrack: Track?
    @Published var isBuffering: Bool = false
    @Published var artwork: UIImage?
    
    let sleepTimerService = SleepTimerService()
    
    private init() {
        // Observer les changements dans le service audio
        audioService.$isPlaying
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
        
        audioService.$isBuffering
            .assign(to: \.isBuffering, on: self)
            .store(in: &cancellables)
        
        audioService.$currentTrack
            .sink { [weak self] track in
                guard let self = self, let track = track else { return }
                self.currentTrack = track
                self.updateArtwork(for: track)
            }
            .store(in: &cancellables)
            
        // Configuration des commandes de lecture à distance (Control Center, écran de verrouillage)
        setupRemoteCommandCenter()
    }
    
    func play(station: Station) {
        if currentStation?.id != station.id {
            // Nouvelle station
            currentStation = station  // Assurons-nous que cette ligne est bien présente
            audioService.play(station: station)
        } else if !isPlaying {
            // Même station, juste reprendre la lecture
            audioService.togglePlayPause()
        }
    }

    func togglePlayPause() {
        audioService.togglePlayPause()
        // Ne pas modifier currentStation ici
    }

    func stop() {
        audioService.stop()
        currentStation = nil  // Cette ligne réinitialise la station et fait disparaître le mini player
        artwork = nil
    }

    func setupSleepTimer(duration: TimeInterval) {
        sleepTimerService.startTimer(duration: duration) { [weak self] in
            self?.stop()
        }
    }
    
    func cancelSleepTimer() {
        sleepTimerService.stopTimer()
    }
    
    private func updateArtwork(for track: Track) {
        // Réutiliser le code du ArtworkService
        Task {
            do {
                let artworkService = ArtworkService()
                let image = try await artworkService.fetchArtwork(for: track)
                await MainActor.run {
                    self.artwork = image ?? UIImage(named: "default_artwork")
                    self.updateNowPlayingInfo()
                }
            } catch {
                print("Failed to fetch artwork: \(error)")
                await MainActor.run {
                    self.artwork = UIImage(named: "default_artwork")
                    self.updateNowPlayingInfo()
                }
            }
        }
    }
    
    // Configuration du centre de commande à distance (iOS Control Center)
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Commande lecture/pause
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            
            if !self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            
            if self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            
            self.togglePlayPause()
            return .success
        }
    }
    
    // Mise à jour des informations de lecture actuelles pour le centre de contrôle iOS
    private func updateNowPlayingInfo() {
        guard let station = currentStation else { return }
        
        var nowPlayingInfo = [String: Any]()
        
        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        } else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = station.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = station.subtitle
        }
        
        // Ajouter l'artwork s'il est disponible
        if let artwork = self.artwork {
            let mpArtwork = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = mpArtwork
        }
        
        // Ajouter l'état de lecture
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Mettre à jour le centre d'information
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
