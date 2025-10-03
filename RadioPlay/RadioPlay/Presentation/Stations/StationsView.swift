import SwiftUI

struct StationsView: View {
    @StateObject private var viewModel = StationsViewModel()
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @State private var searchText = ""
    @State private var selectedCategory: StationCategory = .all
    @State private var showSettings = false
    @State private var isSearchExpanded = false  // ✅ NOUVEAU
    @FocusState private var isSearchFocused: Bool  // ✅ NOUVEAU
    @State private var showAddStation = false  // ✅ NOUVEAU

    enum StationCategory: String, CaseIterable {
        case all = "Toutes"
        case favorites = "Favoris"
        case news = "Actualités"
        case music = "Musique"
        case sport = "Sport"
        case culture = "Culture"

        // ✅ NOUVEAU - Icônes pour chaque catégorie
        var icon: String {
            switch self {
            case .all: return "radio"
            case .favorites: return "heart.fill"
            case .news: return "newspaper.fill"
            case .music: return "music.note"
            case .sport: return "sportscourt.fill"
            case .culture: return "theatermasks.fill"
            }
        }

        var color: Color {
            switch self {
            case .all: return .blue
            case .favorites: return .red
            case .news: return .orange
            case .music: return .purple
            case .sport: return .green
            case .culture: return .pink
            }
        }
    }

    var filteredStations: [Station] {
        let searchFiltered = searchText.isEmpty ?
            viewModel.stations :
            viewModel.stations.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
            }

        switch selectedCategory {
        case .all:
            return searchFiltered
        case .favorites:
            return searchFiltered.filter { viewModel.isFavorite(station: $0) }
        case .news:
            return searchFiltered.filter {
                $0.subtitle.localizedCaseInsensitiveContains("info") ||
                $0.subtitle.localizedCaseInsensitiveContains("actualité") ||
                $0.name.localizedCaseInsensitiveContains("info") ||
                $0.name.localizedCaseInsensitiveContains("france info")
            }
        case .music:
            return searchFiltered.filter {
                $0.subtitle.localizedCaseInsensitiveContains("music") ||
                $0.subtitle.localizedCaseInsensitiveContains("hit") ||
                $0.name.localizedCaseInsensitiveContains("NRJ") ||
                $0.name.localizedCaseInsensitiveContains("RTL2") ||
                $0.name.localizedCaseInsensitiveContains("Fun") ||
                $0.name.localizedCaseInsensitiveContains("Skyrock") ||
                $0.name.localizedCaseInsensitiveContains("Virgin") ||
                $0.name.localizedCaseInsensitiveContains("Radio Classique")
            }
        case .sport:
            return searchFiltered.filter {
                $0.subtitle.localizedCaseInsensitiveContains("sport") ||
                $0.name.localizedCaseInsensitiveContains("RMC") ||
                $0.name.localizedCaseInsensitiveContains("sport")
            }
        case .culture:
            return searchFiltered.filter {
                $0.subtitle.localizedCaseInsensitiveContains("culture") ||
                $0.name.localizedCaseInsensitiveContains("France Culture") ||
                $0.name.localizedCaseInsensitiveContains("France Inter")
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Fond avec dégradé
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // ✅ NOUVEAU - En-tête compact avec recherche intégrée
                    compactHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // ✅ NOUVEAU - Catégories redessinées
                    modernCategoriesBar
                        .padding(.bottom, 8)

                    // Indicateur de chargement en arrière-plan
                    if viewModel.isLoading && !viewModel.stations.isEmpty {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                            Text("Mise à jour...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                    }

                    // Contenu principal
                    if !viewModel.hasInitiallyLoaded && viewModel.stations.isEmpty {
                        InitialLoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.stations.isEmpty {
                        ErrorView(message: errorMessage) {
                            Task {
                                await viewModel.loadStations()
                            }
                        }
                    } else if filteredStations.isEmpty {
                        EmptyStateView(
                            category: selectedCategory,
                            searchText: searchText
                        )
                    } else {
                        stationsList
                    }
                }

                // ✅ NOUVEAU - Bouton flottant pour ajouter une station
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddStation = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.blue.opacity(0.5), radius: 15, x: 0, y: 8)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100) // Au-dessus du mini player
                    }
                }

                if showSettings {
                    SettingsView(isPresented: $showSettings)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .navigationBarHidden(true)
            .task {
                if viewModel.stations.isEmpty || !viewModel.hasInitiallyLoaded {
                    await viewModel.loadStations()
                }
            }
            .refreshable {
                await viewModel.loadStations()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Composants

    // ✅ NOUVEAU - En-tête compact
    private var compactHeader: some View {
        HStack(spacing: 12) {
            // Titre ou barre de recherche
            if isSearchExpanded {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))

                    TextField("Rechercher", text: $searchText)
                        .foregroundColor(.white)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .transition(.scale.combined(with: .opacity))
            } else {
                Text("Radio Play")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))

                Spacer()
            }

            // Boutons d'action
            HStack(spacing: 12) {
                // Bouton recherche
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSearchExpanded.toggle()
                        if isSearchExpanded {
                            isSearchFocused = true
                        } else {
                            searchText = ""
                            isSearchFocused = false
                        }
                    }
                }) {
                    Image(systemName: isSearchExpanded ? "xmark" : "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }

                // Bouton paramètres
                if !isSearchExpanded {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchExpanded)
    }

    private var modernCategoriesBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(StationCategory.allCases, id: \.self) { category in
                        ModernCategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                    // ✅ Scroll vers la catégorie sélectionnée
                                    proxy.scrollTo(category, anchor: .center)
                                }
                            }
                        )
                        .id(category)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)  // iOS 16+, sinon supprimer cette ligne
        }
    }

    // Liste des stations
    private var stationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredStations) { station in
                    Button(action: {
                        handleStationTap(station)
                    }) {
                        CompactStationCard(
                            station: station,
                            isFavorite: viewModel.isFavorite(station: station),
                            isPlaying: audioManager.currentStation?.id == station.id && audioManager.isPlaying,
                            onFavoriteToggle: {
                                viewModel.toggleFavorite(station: station)
                            },
                            onPlayToggle: {
                                handleStationTap(station)
                            },
                            onDelete: viewModel.isCustomStation(station.id) ? {
                                viewModel.removeCustomStation(station.id)
                            } : nil,
                            isCustom: viewModel.isCustomStation(station.id)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Espace pour le mini player
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

// ✅ NOUVEAU - Bouton de catégorie moderne
struct ModernCategoryButton: View {
    let category: StationsView.StationCategory
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                Text(category.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        category.color,
                                        category.color.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: category.color.opacity(0.4), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                    }
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressAction(onPress: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        }, onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        })
    }
}

// ✅ NOUVEAU - Carte de station plus compacte
struct CompactStationCard: View {
    let station: Station
    let isFavorite: Bool
    let isPlaying: Bool
    let onFavoriteToggle: () -> Void
    let onPlayToggle: () -> Void
    let onDelete: (() -> Void)?  // ✅ NOUVEAU
    let isCustom: Bool  // ✅ NOUVEAU

    var body: some View {
        HStack(spacing: 12) {
            // Logo de la station
            AsyncImage(url: URL(string: station.logoURL ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.15))
                        .frame(width: 56, height: 56)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: isPlaying ? Color.blue.opacity(0.4) : Color.black.opacity(0.2), radius: isPlaying ? 8 : 4, x: 0, y: 2)
                case .failure:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.15))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "radio")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }

            // Infos de la station
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(station.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                // Statut
                HStack(spacing: 4) {
                    Circle()
                        .fill(isPlaying ? Color.green : Color.red)
                        .frame(width: 6, height: 6)

                    Text(isPlaying ? "En écoute" : "En direct")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Boutons d'action
            HStack(spacing: 8) {
                // Favori
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isFavorite ? .red : .gray)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                // Lecture
                Button(action: onPlayToggle) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isPlaying ? Color.green : Color.blue)
                                .shadow(color: isPlaying ? Color.green.opacity(0.4) : Color.blue.opacity(0.4), radius: 6, x: 0, y: 2)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isPlaying ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        // ✅ NOUVEAU - Menu contextuel pour les stations custom
                .contextMenu {
                    if isCustom {
                        Button(role: .destructive, action: {
                            onDelete?()
                        }) {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
                }
    }
}

// Extensions inchangées
extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

// Vues helpers (garder les versions précédentes ou simplifiées)
struct InitialLoadingView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image("radio-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .opacity(0.8)

            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)

                Text("Chargement...")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "wifi.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("Connexion impossible")
                .font(.headline)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Réessayer")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 30)
                .background(Color.blue)
                .cornerRadius(25)
            }

            Spacer()
        }
    }
}

struct EmptyStateView: View {
    let category: StationsView.StationCategory
    let searchText: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: searchText.isEmpty ? "radio" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(emptyTitle)
                .font(.headline)
                .foregroundColor(.white)

            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    private var emptyTitle: String {
        if !searchText.isEmpty {
            return "Aucun résultat"
        }
        switch category {
        case .favorites:
            return "Aucun favori"
        default:
            return "Aucune station"
        }
    }

    private var emptyMessage: String {
        if !searchText.isEmpty {
            return "Essayez une autre recherche"
        }
        switch category {
        case .favorites:
            return "Ajoutez des stations à vos favoris en appuyant sur le cœur"
        default:
            return "Aucune station disponible"
        }
    }
}
