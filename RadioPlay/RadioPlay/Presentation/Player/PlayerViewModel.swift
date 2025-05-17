//
//  PlayerViewModel.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Player/PlayerViewModel.swift
import Foundation
import UIKit
import MediaPlayer
import Combine

class PlayerViewModel: ObservableObject {
    // État
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var currentTrack: Track?
    @Published var artwork: UIImage?
    
    // Services
    private let audioService = AudioPlayerService()
    private let artworkService = ArtworkService()
    let sleepTimerService = SleepTimerService()

    // Données
    private let station: Station
    private var cancellables = Set<AnyCancellable>()

    init(station: Station) {
        self.station = station
        
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
    }
    
    func startPlaying() {
        audioService.play(station: station)
    }
    
    func stopPlaying() {
        audioService.stop()
    }
    
    func togglePlayPause() {
        audioService.togglePlayPause()
    }
    
    private func updateArtwork(for track: Track) {
        Task {
            do {
                let image = try await artworkService.fetchArtwork(for: track)
                await MainActor.run {
                    self.artwork = image ?? UIImage(named: "default_artwork")
                }
            } catch {
                print("Failed to fetch artwork: \(error)")
                await MainActor.run {
                    self.artwork = UIImage(named: "default_artwork")
                }
            }
        }
    }
    
    func shareTrack() {
        guard let track = currentTrack else { return }

        let text = "J'écoute \(track.title) par \(track.artist) sur \(station.name) via Radio Play!"

        var items: [Any] = [text]

        if let artwork = artwork {
            items.append(artwork)
        }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Utiliser AppUtility au lieu de App
        if let rootVC = AppUtility.rootViewController {
            rootVC.present(activityViewController, animated: true)
        }
    }

    func openInAppleMusic() {
        guard let track = currentTrack else { return }
        
        // Construire la requête de recherche pour Apple Music
        let query = "\(track.artist) \(track.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://music.apple.com/search?term=\(query)"
        
        guard let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url)
    }

    func setupSleepTimer(duration: TimeInterval) {
        sleepTimerService.startTimer(duration: duration) { [weak self] in
            self?.stopPlaying()
        }
    }

    func cancelSleepTimer() {
        sleepTimerService.stopTimer()
    }
}
