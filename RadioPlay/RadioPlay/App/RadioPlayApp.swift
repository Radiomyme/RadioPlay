//
//  RadioPlayApp.swift modifié
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI
import AVFoundation
import CoreData
import MediaPlayer  // Ajout de cet import

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

            // Assurez-vous que cette ligne est présente et exécutée
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
            // Assurons-nous que l'animation est correcte et liée à l'état du currentStation
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
