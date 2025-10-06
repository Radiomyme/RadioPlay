import SwiftUI
import AVFoundation
import CoreData
import MediaPlayer

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

                    if audioManager.currentStation != nil {
                        AdvancedMiniPlayerView()
                            .environmentObject(audioManager)
                            .transition(.move(edge: .bottom))
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
                    options: [.allowAirPlay, .allowBluetoothHFP]
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
}
