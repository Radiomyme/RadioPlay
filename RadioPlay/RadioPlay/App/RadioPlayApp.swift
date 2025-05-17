//
//  RadioPlayApp.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI
import CoreData

@main
struct RadioPlayApp: App {
    // Ajoutez cette propriété pour le contexte persistant
    let persistenceController = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            StationsView()
                .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
        }
    }
}
