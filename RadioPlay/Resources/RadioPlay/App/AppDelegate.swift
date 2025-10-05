import UIKit
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {

    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        initializeAudioSession()
        application.beginReceivingRemoteControlEvents()
        _ = ThemeManager.shared
        return true
    }

    // MARK: - App Lifecycle

    func applicationDidEnterBackground(_ application: UIApplication) {
        startBackgroundTask()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        initializeAudioSession()
        ThemeManager.shared.applyTheme()
        endBackgroundTask()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        endBackgroundTask()
    }

    // MARK: - Audio Session

    private func initializeAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                policy: .longFormAudio,
                options: [.mixWithOthers, .allowAirPlay, .allowBluetoothHFP]
            )

            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            Logger.log("Audio session initialization failed: \(error)", category: .audio, type: .error)
        }
    }

    // MARK: - Background Task

    private func startBackgroundTask() {
        endBackgroundTask()

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

// MARK: - Notification Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
