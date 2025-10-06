import SwiftUI
import AVFoundation
import os

@main
struct RadioPlayTVApp: App {
    @StateObject private var audioManager = AudioPlayerManager.shared
    @UIApplicationDelegateAdaptor(AppDelegateTV.self) var appDelegate

    init() {
        setupAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            MainTVView()
                .environmentObject(audioManager)
                .preferredColorScheme(.dark)
        }
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Logger.log("Audio session setup failed: \(error)", category: .audio, type: .error)
        }
    }
}

// MARK: - AppDelegate pour tvOS

class AppDelegateTV: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // L'audio continue en arrière-plan
    }
}
