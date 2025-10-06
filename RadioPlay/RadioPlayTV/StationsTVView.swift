import SwiftUI

struct StationsTVView: View {
    @EnvironmentObject private var viewModel: StationsViewModel
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @State private var selectedCategory: String = "all"
    @Namespace private var animation

    // Filter out custom stations on tvOS (can't be created here)
    private var availableStations: [Station] {
        viewModel.stations.filter { station in
            !viewModel.isCustomStation(station.id)
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 400, maximum: 500), spacing: 40)
    ]

    var filteredStations: [Station] {
        viewModel.getStationsByCategory(category: selectedCategory)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                headerSection

                // Categories
                categoriesSection

                // Stations Grid
                stationsGrid
            }
            .padding(60)
            .padding(.bottom, audioManager.currentStation != nil ? 200 : 60)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Vos Radios")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(filteredStations.count) stations disponibles")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
            }

            Spacer()

            if viewModel.isLoading {
                HStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Mise à jour...")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // MARK: - Categories

    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                CategoryButtonTV(
                    title: "Toutes",
                    icon: "radio",
                    isSelected: selectedCategory == "all",
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = "all"
                    }
                }

                if !viewModel.favoriteStations.isEmpty {
                    CategoryButtonTV(
                        title: "Favoris",
                        icon: "heart.fill",
                        isSelected: selectedCategory == "favorites",
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = "favorites"
                        }
                    }
                }

                CategoryButtonTV(
                    title: "Actualités",
                    icon: "newspaper.fill",
                    isSelected: selectedCategory == "news",
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = "news"
                    }
                }

                CategoryButtonTV(
                    title: "Musique",
                    icon: "music.note",
                    isSelected: selectedCategory == "music",
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = "music"
                    }
                }

                CategoryButtonTV(
                    title: "Sport",
                    icon: "sportscourt.fill",
                    isSelected: selectedCategory == "sport",
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = "sport"
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Stations Grid

    private var stationsGrid: some View {
        LazyVGrid(columns: columns, spacing: 40) {
            ForEach(filteredStations) { station in
                StationCardTV(
                    station: station,
                    isFavorite: viewModel.isFavorite(station: station),
                    isPlaying: audioManager.currentStation?.id == station.id && audioManager.isPlaying,
                    onPlay: {
                        handleStationTap(station)
                    },
                    onToggleFavorite: {
                        viewModel.toggleFavorite(station: station)
                    }
                )
            }
        }
    }

    private func handleStationTap(_ station: Station) {
        if audioManager.currentStation?.id == station.id {
            audioManager.togglePlayPause()
        } else {
            audioManager.play(station: station)
        }
    }
}

// MARK: - Category Button

struct CategoryButtonTV: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))

                Text(title)
                    .font(.system(size: 28, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .matchedGeometryEffect(id: "category", in: namespace)
                    } else if isFocused {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    }
                }
            )
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Station Card

struct StationCardTV: View {
    let station: Station
    let isFavorite: Bool
    let isPlaying: Bool
    let onPlay: () -> Void
    let onToggleFavorite: () -> Void

    @FocusState private var isFocused: Bool
    @State private var showMenu = false

    var body: some View {
        Button(action: onPlay) {
            VStack(spacing: 0) {
                // Logo
                ZStack {
                    AsyncImage(url: URL(string: station.logoURL ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.5)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        case .failure:
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "radio")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 280)

                    // Playing Indicator
                    if isPlaying {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "waveform")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                    .padding(16)
                                    .background(Circle().fill(Color.black.opacity(0.7)))
                                    .padding(20)
                            }
                            Spacer()
                        }
                    }

                    // Favorite Badge
                    if isFavorite {
                        VStack {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                    .padding(12)
                                    .background(Circle().fill(Color.black.opacity(0.7)))
                                    .padding(20)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(station.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(station.subtitle)
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isPlaying ? Color.green : Color.red)
                            .frame(width: 12, height: 12)

                        Text(isPlaying ? "En écoute" : "En direct")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .background(cardBackground)
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .shadow(
                color: isFocused ? Color.blue.opacity(0.5) : Color.clear,
                radius: 30,
                x: 0,
                y: 10
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .contextMenu {
            Button(action: onToggleFavorite) {
                Label(
                    isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                    systemImage: isFavorite ? "heart.slash" : "heart"
                )
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isFocused ? 0.15 : 0.08),
                        Color.white.opacity(isFocused ? 0.1 : 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isPlaying ? Color.blue.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: isPlaying ? 3 : 1
                    )
            )
    }
}
