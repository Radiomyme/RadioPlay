//
//  RadioPlayApp.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

// App/RadioPlayApp.swift
import SwiftUI
import AVFoundation
import CoreData

@main
struct RadioPlayApp: SwiftUI.App {
    // Initialisation de l'application
    init() {
        // Configuration de la session audio pour le fonctionnement en arrière-plan
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Échec de la configuration de la session audio: \(error)")
        }
    }

    // Gestionnaire Core Data
    let persistenceController = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            StationsView()
                .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
