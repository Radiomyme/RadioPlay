//
//  RadioPlayApp.swift modifié
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI
import AVFoundation
import CoreData
import MediaPlayer

@main
struct RadioPlayApp: SwiftUI.App {
    @StateObject private var audioManager = AudioPlayerManager.shared

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            setupRemoteCommands()
        } catch {
            print("Échec de la configuration de la session audio: \(error)")
        }
    }

    let persistenceController = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
                    .environmentObject(audioManager)
                    .preferredColorScheme(.dark)

                // Mini player fixé en bas
                VStack {
                    Spacer()
                    if audioManager.currentStation != nil {
                        AdvancedMiniPlayerView()
                            .environmentObject(audioManager)
                            .transition(.move(edge: .bottom))
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .animation(.easeInOut(duration: 0.3), value: audioManager.currentStation != nil)
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
    }
}
