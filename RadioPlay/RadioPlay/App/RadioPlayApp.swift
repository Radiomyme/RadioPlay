//
//  RadioPlayApp.swift modifié
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI
import AVFoundation
import CoreData

@main
struct RadioPlayApp: SwiftUI.App {
    // Gestionnaire audio partagé pour toute l'application
    @StateObject private var audioManager = AudioPlayerManager.shared

    // Initialisation de l'application
    init() {
        // Configuration de la session audio pour le fonctionnement en arrière-plan
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

            // Activer les commandes de lecture en arrière-plan
            setupRemoteCommands()
        } catch {
            print("Échec de la configuration de la session audio: \(error)")
        }
    }

    // Gestionnaire Core Data
    let persistenceController = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
                    .environmentObject(audioManager)
                    .preferredColorScheme(.dark)

                // Mini player visible uniquement lorsqu'une station est en cours de lecture
                if audioManager.currentStation != nil {
                    MiniPlayerView()
                        .environmentObject(audioManager)
                        .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut, value: audioManager.currentStation != nil)
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Activer les commandes de base
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
    }
}

// Gestionnaire audio global pour maintenir l'état entre les vues
class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    private let audioService = AudioPlayerService()
    private var cancellables = Set<AnyCancellable>()

    @Published var currentStation: Station?
    @Published var isPlaying: Bool = false
    @Published var currentTrack: Track?
    @Published var isBuffering: Bool = false
    @Published var artwork: UIImage?

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
    }

    func play(station: Station) {
        if currentStation?.id != station.id {
            // Nouvelle station
            currentStation = station
            audioService.play(station: station)
        } else if !isPlaying {
            // Même station, juste reprendre la lecture
            audioService.togglePlayPause()
        }
    }

    func togglePlayPause() {
        audioService.togglePlayPause()
    }

    func stop() {
        audioService.stop()
        currentStation = nil
        artwork = nil
    }

    private func updateArtwork(for track: Track) {
        // Réutiliser le code du ArtworkService
        Task {
            do {
                let artworkService = ArtworkService()
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
}
