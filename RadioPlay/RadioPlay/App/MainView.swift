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
                // Pas besoin de padding fixe car le player avancé gère son propre espace
        }
    }
}
