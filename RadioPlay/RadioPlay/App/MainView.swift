//
//  MainView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var stationsViewModel = StationsViewModel()
    @EnvironmentObject private var audioManager: AudioPlayerManager

    var body: some View {
        ZStack {
            StationsView()
                .environmentObject(stationsViewModel)
                .environmentObject(audioManager)
                // Ajouter du padding en bas lorsque le mini-player est actif
                .padding(.bottom, audioManager.currentStation != nil ? 70 : 0)
                .animation(.easeInOut, value: audioManager.currentStation != nil)
        }
    }
}
