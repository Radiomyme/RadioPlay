//
//  MainTVView.swift
//  RadioPlay TV
//
//  Created by Martin Parmentier on 06/10/2025.
//

import SwiftUI

struct MainTVView: View {
    @StateObject private var stationsViewModel = StationsViewModel()
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @State private var selectedCategory: StationCategory = .all

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundGradient

                HStack(spacing: 0) {
                    // SIDEBAR GAUCHE - Catégories
                    SidebarCategoriesTV(selectedCategory: $selectedCategory)
                        .frame(width: 320)

                    // CENTRE - Grille de stations
                    StationsContentTV(
                        stations: filteredStations,
                        categoryTitle: selectedCategory.title
                    )
                    .environmentObject(stationsViewModel)
                    .environmentObject(audioManager)
                    .frame(maxWidth: .infinity)

                    // DROITE - Player fixe et compact
                    if audioManager.currentStation != nil {
                        CompactPlayerSidebarTV()
                            .environmentObject(audioManager)
                            .environmentObject(stationsViewModel)
                            .frame(width: 380)
                            .transition(.move(edge: .trailing))
                    }
                }
            }
        }
        .task {
            await stationsViewModel.loadStations()
        }
    }

    private var filteredStations: [Station] {
        switch selectedCategory {
        case .all:
            return stationsViewModel.stations
        case .favorites:
            return stationsViewModel.favoriteStations
        case .news:
            return stationsViewModel.stations.filter { station in
                guard let categories = station.categories else { return false }
                return categories.contains { $0.lowercased().contains("news") || $0.lowercased().contains("actualités") }
            }
        case .music:
            return stationsViewModel.stations.filter { station in
                guard let categories = station.categories else { return false }
                return categories.contains { $0.lowercased().contains("music") || $0.lowercased().contains("musique") }
            }
        case .sport:
            return stationsViewModel.stations.filter { station in
                guard let categories = station.categories else { return false }
                return categories.contains { $0.lowercased().contains("sport") }
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.08, green: 0.08, blue: 0.15), location: 0.0),
                .init(color: Color.black, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Station Category

enum StationCategory: CaseIterable {
    case all
    case favorites
    case news
    case music
    case sport

    var title: String {
        switch self {
        case .all: return "Toutes"
        case .favorites: return "Favoris"
        case .news: return "Actualités"
        case .music: return "Musique"
        case .sport: return "Sport"
        }
    }

    var icon: String {
        switch self {
        case .all: return "radio"
        case .favorites: return "heart.fill"
        case .news: return "newspaper.fill"
        case .music: return "music.note"
        case .sport: return "sportscourt.fill"
        }
    }
}

// MARK: - Sidebar Categories

struct SidebarCategoriesTV: View {
    @Binding var selectedCategory: StationCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        Image(systemName: "radio.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Radio Play")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("15 stations")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 50)
            .padding(.bottom, 36)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 28)

            // Catégories
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(StationCategory.allCases, id: \.self) { category in
                        CategoryRowTV(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.3)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.02), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        )
    }
}

struct CategoryRowTV: View {
    let category: StationCategory
    let isSelected: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Bouton invisible EN ARRIÈRE-PLAN
            Button(action: action) {
                Color.clear
            }
            .buttonStyle(.plain)
            .focused($isFocused)
            .focusEffectDisabled()

            // Contenu visible AU PREMIER PLAN
            HStack(spacing: 16) {
                // Icône
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 44)

                // Texte
                Text(category.title)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(textColor)

                Spacer()

                // Indicateur
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: 4, height: 32)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .allowsHitTesting(false)
        }
    }

    private var iconColor: Color {
        if isSelected { return .white }
        else if isFocused { return .white.opacity(0.9) }
        return .gray
    }

    private var textColor: Color {
        if isSelected || isFocused { return .white }
        return .gray
    }

    private var backgroundColor: Color {
        if isSelected { return Color.blue.opacity(0.25) }
        else if isFocused { return Color.white.opacity(0.1) }
        return Color.clear
    }
}

// MARK: - Stations Content

struct StationsContentTV: View {
    let stations: [Station]
    let categoryTitle: String
    @EnvironmentObject var stationsViewModel: StationsViewModel
    @EnvironmentObject var audioManager: AudioPlayerManager

    private let columns = [
        GridItem(.adaptive(minimum: 340, maximum: 380), spacing: 50)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Titre
                Text(categoryTitle)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.top, 50)

                // Grille CARRÉE
                LazyVGrid(columns: columns, spacing: 50) {
                    ForEach(stations) { station in
                        SquareStationCardTV(station: station)
                            .environmentObject(stationsViewModel)
                            .environmentObject(audioManager)
                    }
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Square Station Card

struct SquareStationCardTV: View {
    let station: Station
    @EnvironmentObject var stationsViewModel: StationsViewModel
    @EnvironmentObject var audioManager: AudioPlayerManager
    @FocusState private var isFocused: Bool

    private var isPlaying: Bool {
        audioManager.currentStation?.id == station.id && audioManager.isPlaying
    }

    private var isFavorite: Bool {
        stationsViewModel.isFavorite(station: station)
    }

    var body: some View {
        ZStack {
            // Bouton invisible EN ARRIÈRE-PLAN
            Button(action: handleTap) {
                Color.clear
            }
            .buttonStyle(.plain)
            .focused($isFocused)
            .focusEffectDisabled()

            // Contenu visible AU PREMIER PLAN
            VStack(spacing: 0) {
                // Image CARRÉE
                ZStack {
                    if let imageURL = station.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_), .empty:
                                placeholderView
                            @unknown default:
                                placeholderView
                            }
                        }
                    } else {
                        placeholderView
                    }
                }
                .frame(width: 380, height: 280)
                .clipped()
                .overlay(gradientOverlay)
                .overlay(topBadges, alignment: .topTrailing)

                // Info compacte
                VStack(alignment: .leading, spacing: 8) {
                    Text(station.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(isPlaying ? Color.green : Color.blue.opacity(0.6))
                            .frame(width: 8, height: 8)

                        Text(isPlaying ? "En écoute" : "En direct")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)

                        if isPlaying {
                            Spacer()
                            HStack(spacing: 3) {
                                ForEach(0..<4) { i in
                                    WaveBarTV(delay: Double(i) * 0.15)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .frame(height: 100)
            }
            .frame(width: 380, height: 380)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isFocused ? 3 : 0)
            )
            .shadow(color: shadowColor, radius: isFocused ? 25 : 12, x: 0, y: isFocused ? 12 : 6)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isFocused)
            .allowsHitTesting(false)
        }
        .contextMenu {
            Button(action: toggleFavorite) {
                Label(
                    isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                    systemImage: isFavorite ? "heart.slash.fill" : "heart.fill"
                )
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "radio.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.4), Color.clear, Color.black.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topBadges: some View {
        HStack(spacing: 10) {
            if isPlaying {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 7, height: 7)
                    Text("LIVE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.7)))
            }

            if isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.7)))
            }
        }
        .padding(12)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isFocused ? 0.12 : 0.08),
                        Color.white.opacity(isFocused ? 0.08 : 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var borderColor: Color {
        if isPlaying { return Color.blue }
        else if isFocused { return Color.white.opacity(0.5) }
        return Color.clear
    }

    private var shadowColor: Color {
        if isPlaying { return Color.blue.opacity(0.4) }
        else if isFocused { return Color.black.opacity(0.5) }
        return Color.black.opacity(0.3)
    }

    private func handleTap() {
        if audioManager.currentStation?.id == station.id {
            audioManager.togglePlayPause()
        } else {
            Task {
                await audioManager.play(station: station)
            }
        }
    }

    private func toggleFavorite() {
        stationsViewModel.toggleFavorite(station: station)
    }
}

struct WaveBarTV: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.green)
            .frame(width: 3, height: isAnimating ? 14 : 5)
            .animation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(delay),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

// MARK: - Compact Player Sidebar

struct CompactPlayerSidebarTV: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var stationsViewModel: StationsViewModel
    @FocusState private var playButtonFocused: Bool
    @FocusState private var stopButtonFocused: Bool
    @FocusState private var favoriteButtonFocused: Bool

    private var isFavorite: Bool {
        if let station = audioManager.currentStation {
            return stationsViewModel.isFavorite(station: station)
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("En écoute")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 50)
                .padding(.bottom, 28)

            ScrollView {
                VStack(spacing: 28) {
                    // Artwork
                    ZStack {
                        Group {
                            if let artwork = audioManager.artwork {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else if let imageURL = audioManager.currentStation?.imageURL,
                                      let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    placeholderArtwork
                                }
                            } else {
                                placeholderArtwork
                            }
                        }
                        .frame(width: 240, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                        // Live
                        if audioManager.isPlaying {
                            VStack {
                                HStack {
                                    Spacer()
                                    liveIndicator
                                        .padding(12)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    // Info
                    VStack(spacing: 10) {
                        if let track = audioManager.currentTrack, !track.title.isEmpty {
                            Text(track.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            Text(track.artist)
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        } else {
                            Text(audioManager.currentStation?.name ?? "")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            Text(audioManager.currentStation?.subtitle ?? "")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }

                        // Status
                        HStack(spacing: 8) {
                            if audioManager.isPlaying && !audioManager.isBuffering {
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { i in
                                        WaveBarTV(delay: Double(i) * 0.1)
                                    }
                                }
                                .frame(width: 40)
                            }

                            Circle()
                                .fill(audioManager.isPlaying ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)

                            Text(audioManager.isPlaying ? "En direct" : "En pause")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 32)

                    // Contrôles
                    VStack(spacing: 16) {
                        // Play/Pause
                        ZStack {
                            // Bouton invisible EN ARRIÈRE-PLAN
                            Button(action: { audioManager.togglePlayPause() }) {
                                Color.clear
                            }
                            .buttonStyle(.plain)
                            .focused($playButtonFocused)
                            .focusEffectDisabled()

                            // Contenu visible AU PREMIER PLAN
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: playButtonFocused ? 88 : 80, height: playButtonFocused ? 88 : 80)
                                .overlay(
                                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .offset(x: audioManager.isPlaying ? 0 : 2)
                                )
                                .allowsHitTesting(false)
                        }

                        HStack(spacing: 14) {
                            // Favori
                            ZStack {
                                // Bouton invisible EN ARRIÈRE-PLAN
                                Button(action: toggleFavorite) {
                                    Color.clear
                                }
                                .buttonStyle(.plain)
                                .focused($favoriteButtonFocused)
                                .focusEffectDisabled()

                                // Contenu visible AU PREMIER PLAN
                                HStack(spacing: 8) {
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 18))
                                    Text(isFavorite ? "Favori" : "Favori")
                                        .font(.system(size: 18, weight: .medium))
                                }
                                .foregroundColor(isFavorite ? .red : .white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(favoriteButtonFocused ? Color.white.opacity(0.2) : Color.white.opacity(0.12))
                                )
                                .allowsHitTesting(false)
                            }

                            // Stop
                            ZStack {
                                // Bouton invisible EN ARRIÈRE-PLAN
                                Button(action: { audioManager.stop() }) {
                                    Color.clear
                                }
                                .buttonStyle(.plain)
                                .focused($stopButtonFocused)
                                .focusEffectDisabled()

                                // Contenu visible AU PREMIER PLAN
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 18))
                                    Text("Stop")
                                        .font(.system(size: 18, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(stopButtonFocused ? Color.white.opacity(0.2) : Color.white.opacity(0.12))
                                )
                                .allowsHitTesting(false)
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 40)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.4)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.03), Color.clear],
                                startPoint: .trailing,
                                endPoint: .leading
                            )
                        )
                )
        )
    }

    private var placeholderArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "radio.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    private var liveIndicator: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.red)
                .frame(width: 7, height: 7)
            Text("LIVE")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.7)))
    }

    private func toggleFavorite() {
        if let station = audioManager.currentStation {
            stationsViewModel.toggleFavorite(station: station)
        }
    }
}
