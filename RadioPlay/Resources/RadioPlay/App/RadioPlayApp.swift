import SwiftUI
import AVFoundation
import CoreData
import MediaPlayer
import AppTrackingTransparency

@main
struct RadioPlayApp: SwiftUI.App {
    @StateObject private var audioManager = AudioPlayerManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = CoreDataManager.shared

    init() {
        StringArrayTransformer.register()
        setupAudioSessionAsync()
        setupRemoteCommands()

        if AppSettings.enableAds {
            AdMobManager.shared.initialize()
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
                    .environmentObject(audioManager)
                    .environmentObject(localizationManager)
                    .environment(\.locale, .init(identifier: localizationManager.currentLanguage.rawValue))

                VStack {
                    Spacer()

                    // Mini player au-dessus de la pub
                    if audioManager.currentStation != nil {
                        AdvancedMiniPlayerView()
                            .environmentObject(audioManager)
                            .transition(.move(edge: .bottom))
                            .zIndex(2)
                    }

                    // Bannière pub tout en bas
                    if AppSettings.enableAds {
                        AdaptiveBannerAdView()
                            .frame(height: 50)
                            .background(Color.black.opacity(0.05))
                            .transition(.move(edge: .bottom))
                            .zIndex(1)
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .animation(.easeInOut(duration: 0.3), value: audioManager.currentStation != nil)
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                localizationManager.objectWillChange.send()
            }
        }
    }

    // MARK: - Setup

    private func setupAudioSessionAsync() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try AVAudioSession.sharedInstance().setCategory(
                    .playback,
                    mode: .default,
                    options: [.allowAirPlay, .allowBluetooth]
                )
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                Logger.log("Audio session setup failed: \(error)", category: .audio, type: .error)
            }
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
    }

    // MARK: - App Tracking Transparency

    private func requestTrackingAuthorization() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        Logger.log("Tracking authorized", category: .network, type: .default)
                    case .denied, .restricted, .notDetermined:
                        Logger.log("Tracking not authorized", category: .network, type: .default)
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}
