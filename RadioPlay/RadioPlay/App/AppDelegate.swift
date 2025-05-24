//
//  AppDelegate.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


import UIKit
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {

    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Initialiser l'audio au lancement
        initializeAudioSession()

        // Activer les contrôles à distance pour l'audio
        application.beginReceivingRemoteControlEvents()

        // Initialiser ThemeManager
        _ = ThemeManager.shared

        print("Application lancée avec succès")
        return true
    }

    // [Reste du code inchangé...]
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Application entrée en arrière-plan via AppDelegate")
        startBackgroundTask()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("Application revenue au premier plan via AppDelegate")
        // Réinitialiser la session audio
        initializeAudioSession()

        // Réappliquer le thème
        ThemeManager.shared.applyTheme()

        endBackgroundTask()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("Application en cours de fermeture via AppDelegate")
        endBackgroundTask()
    }

    // Configuration proactive de l'audio
    private func initializeAudioSession() {
        do {
            // Options avancées pour la robustesse
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                policy: .longFormAudio,
                options: [.mixWithOthers, .allowAirPlay, .allowBluetooth]
            )

            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            print("Session audio initialisée avec succès dans AppDelegate")
        } catch {
            print("Erreur d'initialisation audio dans AppDelegate: \(error)")
        }
    }

    // Gestion avancée des tâches d'arrière-plan
    private func startBackgroundTask() {
        endBackgroundTask()

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("Tâche d'arrière-plan expirée dans AppDelegate")
            self?.endBackgroundTask()
        }

        print("Tâche d'arrière-plan démarrée dans AppDelegate: \(backgroundTask)")
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            print("Tâche d'arrière-plan terminée dans AppDelegate")
        }
    }
}

// Support des notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
