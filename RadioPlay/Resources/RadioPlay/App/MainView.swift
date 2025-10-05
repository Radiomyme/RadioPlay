import SwiftUI

struct MainView: View {
    @StateObject private var stationsViewModel = StationsViewModel()
    @EnvironmentObject private var audioManager: AudioPlayerManager

    var body: some View {
        ZStack {
            if stationsViewModel.isInitialLoadComplete {
                StationsView()
                    .environmentObject(stationsViewModel)
                    .environmentObject(audioManager)
                    .transition(.opacity)
            } else {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stationsViewModel.isInitialLoadComplete)
        .task {
            if !stationsViewModel.isInitialLoadComplete {
                await stationsViewModel.loadStations()
            }
        }
    }
}
