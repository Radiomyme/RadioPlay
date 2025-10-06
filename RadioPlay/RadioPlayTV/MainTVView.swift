//
//  MainTVView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 06/10/2025.
//


import SwiftUI

struct MainTVView: View {
    @StateObject private var stationsViewModel = StationsViewModel()
    @EnvironmentObject private var audioManager: AudioPlayerManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundGradient
                
                // Main Content
                HStack(spacing: 0) {
                    // Sidebar
                    if geometry.size.width > 1200 {
                        SidebarTVView(viewModel: stationsViewModel)
                            .frame(width: 400)
                    }
                    
                    // Main Content Area
                    StationsTVView()
                        .environmentObject(stationsViewModel)
                        .environmentObject(audioManager)
                }
                
                // Now Playing Bar (bottom)
                if audioManager.currentStation != nil {
                    VStack {
                        Spacer()
                        NowPlayingBarTV()
                            .environmentObject(audioManager)
                    }
                }
            }
        }
        .task {
            await stationsViewModel.loadStations()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color.black
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Sidebar

struct SidebarTVView: View {
    @ObservedObject var viewModel: StationsViewModel
    @State private var selectedTab: String = "all"
    
    private let tabs = [
        ("all", "Toutes", "radio"),
        ("favorites", "Favoris", "heart.fill"),
        ("news", "Actualités", "newspaper.fill"),
        ("music", "Musique", "music.note"),
        ("sport", "Sport", "sportscourt.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Logo
            HStack {
                Image(systemName: "radio.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Radio Play")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 60)
            .padding(.leading, 40)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 40)
            
            // Navigation
            VStack(alignment: .leading, spacing: 12) {
                ForEach(tabs, id: \.0) { tab in
                    SidebarButton(
                        title: tab.1,
                        icon: tab.2,
                        isSelected: selectedTab == tab.0,
                        action: { selectedTab = tab.0 }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Version \(AppSettings.appVersion)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(viewModel.stations.count) stations")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black.opacity(0.3))
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .frame(width: 40)
                
                Text(title)
                    .font(.system(size: 26, weight: .semibold))
                
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return Color.blue
        } else if isSelected {
            return Color.white.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}