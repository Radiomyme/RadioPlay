import SwiftUI

struct StationsView: View {
    @StateObject private var viewModel = StationsViewModel()
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @Environment(\.colorScheme) var colorScheme  // ✅ Détection du thème
    @State private var searchText = ""
    @State private var selectedCategory: StationCategory = .all
    @State private var showSettings = false
    @State private var isSearchExpanded = false
    @FocusState private var isSearchFocused: Bool
    @State private var showAddStation = false  // ✅ État pour le sheet

    enum StationCategory: String, CaseIterable {
        case all = "Toutes"
        case favorites = "Favoris"
        case news = "Actualités"
        case music = "Musique"
        case sport = "Sport"
        case culture = "Culture"

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
        let searchFiltered: [Station]

        if searchText.isEmpty {
            searchFiltered = viewModel.stations
        } else {
            searchFiltered = viewModel.stations.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filterByCategory(searchFiltered)
    }

    // ✅ Filtre par catégorie - séparé pour simplifier
    private func filterByCategory(_ stations: [Station]) -> [Station] {
        switch selectedCategory {
        case .all:
            return stations
        case .favorites:
            return stations.filter { viewModel.isFavorite(station: $0) }
        case .news:
            return filterNewsStations(stations)
        case .music:
            return filterMusicStations(stations)
        case .sport:
            return filterSportStations(stations)
        case .culture:
            return filterCultureStations(stations)
        }
    }

    private func filterNewsStations(_ stations: [Station]) -> [Station] {
        stations.filter {
            $0.subtitle.localizedCaseInsensitiveContains("info") ||
            $0.subtitle.localizedCaseInsensitiveContains("actualité") ||
            $0.name.localizedCaseInsensitiveContains("info") ||
            $0.name.localizedCaseInsensitiveContains("france info")
        }
    }

    private func filterMusicStations(_ stations: [Station]) -> [Station] {
        stations.filter {
            $0.subtitle.localizedCaseInsensitiveContains("music") ||
            $0.subtitle.localizedCaseInsensitiveContains("hit") ||
            $0.name.localizedCaseInsensitiveContains("NRJ") ||
            $0.name.localizedCaseInsensitiveContains("RTL2") ||
            $0.name.localizedCaseInsensitiveContains("Fun") ||
            $0.name.localizedCaseInsensitiveContains("Skyrock") ||
            $0.name.localizedCaseInsensitiveContains("Virgin") ||
            $0.name.localizedCaseInsensitiveContains("Radio Classique")
        }
    }

    private func filterSportStations(_ stations: [Station]) -> [Station] {
        stations.filter {
            $0.subtitle.localizedCaseInsensitiveContains("sport") ||
            $0.name.localizedCaseInsensitiveContains("RMC") ||
            $0.name.localizedCaseInsensitiveContains("sport")
        }
    }

    private func filterCultureStations(_ stations: [Station]) -> [Station] {
        stations.filter {
            $0.subtitle.localizedCaseInsensitiveContains("culture") ||
            $0.name.localizedCaseInsensitiveContains("France Culture") ||
            $0.name.localizedCaseInsensitiveContains("France Inter")
        }
    }

    // ✅ Propriété calculée pour le fond - évite l'erreur de compilation
    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                mainContent

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
            .sheet(isPresented: $showAddStation) {
                AddCustomStationView(viewModel: viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // ✅ Contenu principal
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            compactHeader
                .padding(.top, 8)
                .padding(.bottom, 12)

            modernCategoriesBar
                .padding(.bottom, 8)

            loadingIndicator

            contentArea
        }
    }

    // ✅ Indicateur de chargement
    @ViewBuilder
    private var loadingIndicator: some View {
        if viewModel.isLoading && !viewModel.stations.isEmpty {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .blue))
                    .scaleEffect(0.7)
                Text("Mise à jour...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 6)
        }
    }

    // ✅ Zone de contenu principal
    @ViewBuilder
    private var contentArea: some View {
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

    // MARK: - Composants

    // ✅ En-tête avec bouton "+" intégré - DÉCOMPOSÉ
    private var compactHeader: some View {
        HStack(spacing: 12) {
            // Titre ou barre de recherche
            headerLeftContent

            Spacer()

            // Boutons d'action
            headerRightButtons
        }
        .padding(.horizontal, horizontalPadding)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchExpanded)
    }

    // ✅ Partie gauche du header
    @ViewBuilder
    private var headerLeftContent: some View {
        if isSearchExpanded {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))

                TextField("Rechercher", text: $searchText)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
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
            .background(headerSearchBackground)
            .cornerRadius(10)
            .transition(.scale.combined(with: .opacity))
        } else {
            Text("Radio Play")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // ✅ Fond de la barre de recherche
    private var headerSearchBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }

    // ✅ Boutons à droite du header
    @ViewBuilder
    private var headerRightButtons: some View {
        HStack(spacing: 12) {
            // Bouton "+" pour ajouter une station
            if !isSearchExpanded {
                addStationButton
            }

            // Bouton recherche
            searchButton

            // Bouton paramètres
            if !isSearchExpanded {
                settingsButton
            }
        }
    }

    // ✅ Bouton ajouter station
    private var addStationButton: some View {
        Button(action: {
            showAddStation = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(addButtonGradient)
                .clipShape(Circle())
                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var addButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // ✅ Bouton recherche
    private var searchButton: some View {
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
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 40, height: 40)
                .background(buttonBackground)
                .clipShape(Circle())
        }
    }

    // ✅ Bouton paramètres
    private var settingsButton: some View {
        Button(action: {
            showSettings = true
        }) {
            Image(systemName: "info.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 40, height: 40)
                .background(buttonBackground)
                .clipShape(Circle())
        }
        .transition(.scale.combined(with: .opacity))
    }

    // ✅ Fond des boutons
    private var buttonBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
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
                                    proxy.scrollTo(category, anchor: .center)
                                }
                            }
                        )
                        .id(category)
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    // Liste des stations - avec grille adaptative
    private var stationsList: some View {
        ScrollView {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // ✅ Grille pour iPad
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(filteredStations) { station in
                        stationButton(for: station)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 100)
            } else {
                // Liste pour iPhone
                LazyVStack(spacing: 12) {
                    ForEach(filteredStations) { station in
                        stationButton(for: station)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 100)
            }
        }
    }

    // ✅ NOUVEAU - Colonnes adaptatives pour iPad
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    // ✅ Padding adaptatif selon l'appareil
    private var horizontalPadding: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 40 // Plus d'espace sur iPad
        }
        return 16
    }

    // ✅ Bouton pour chaque station
    private func stationButton(for station: Station) -> some View {
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

    private func handleStationTap(_ station: Station) {
        if audioManager.currentStation?.id == station.id {
            audioManager.togglePlayPause()
        } else {
            audioManager.play(station: station)
        }
    }
}

// ✅ Bouton de catégorie moderne
struct ModernCategoryButton: View {
    let category: StationsView.StationCategory
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme  // ✅ Détection du thème

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                Text(category.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .gray : Color(white: 0.4)))
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
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
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

// ✅ Carte de station plus compacte avec tailles adaptatives
struct CompactStationCard: View {
    let station: Station
    let isFavorite: Bool
    let isPlaying: Bool
    let onFavoriteToggle: () -> Void
    let onPlayToggle: () -> Void
    let onDelete: (() -> Void)?
    let isCustom: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var showDeleteAlert = false

    // ✅ NOUVEAU - Tailles adaptatives
    private var logoSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 72 : 56
    }

    private var cardPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12
    }

    private var titleSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 18 : 16
    }

    private var subtitleSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 15 : 13
    }

    var body: some View {
        HStack(spacing: 12) {
            stationLogo
            stationInfo
            Spacer()
            actionButtons
        }
        .padding(cardPadding)
        .background(cardBackground)
        .alert("Supprimer cette station ?", isPresented: $showDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Cette action est irréversible.")
        }
    }

    // ✅ Logo de la station avec taille adaptative
    private var stationLogo: some View {
        AsyncImage(url: URL(string: station.logoURL ?? "")) { phase in
            Group {
                switch phase {
                case .empty:
                    logoPlaceholder
                        .overlay(ProgressView().progressViewStyle(CircularProgressViewStyle(tint: foregroundColor)).scaleEffect(0.7))
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    logoPlaceholder.overlay(Image(systemName: "radio").font(.system(size: logoSize * 0.4)).foregroundColor(.gray))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: logoSize, height: logoSize)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: isPlaying ? Color.blue.opacity(0.4) : Color.black.opacity(0.2), radius: isPlaying ? 8 : 4, x: 0, y: 2)
        }
    }

    private var logoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(logoBackgroundColor)
    }

    // ✅ Infos de la station avec tailles adaptatives
    private var stationInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(station.name)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundColor(titleColor)
                    .lineLimit(1)

                if isCustom {
                    customBadge
                }
            }

            Text(station.subtitle)
                .font(.system(size: subtitleSize))
                .foregroundColor(.gray)
                .lineLimit(1)

            statusIndicator
        }
    }

    private var customBadge: some View {
        Text("Custom")
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(4)
    }

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isPlaying ? Color.green : Color.red)
                .frame(width: 6, height: 6)

            Text(isPlaying ? "En écoute" : "En direct")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    // ✅ Boutons d'action
    private var actionButtons: some View {
        HStack(spacing: 8) {
            if isCustom {
                deleteButton
            }
            favoriteButton
            playButton
        }
    }

    private var deleteButton: some View {
        Button(action: { showDeleteAlert = true }) {
            Image(systemName: "trash")
                .font(.system(size: 16))
                .foregroundColor(.red)
                .frame(width: 36, height: 36)
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var favoriteButton: some View {
        Button(action: onFavoriteToggle) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 18))
                .foregroundColor(isFavorite ? .red : .gray)
                .frame(width: 36, height: 36)
                .background(buttonBackgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var playButton: some View {
        Button(action: onPlayToggle) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(playButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var playButtonBackground: some View {
        Circle()
            .fill(isPlaying ? Color.green : Color.blue)
            .shadow(color: isPlaying ? Color.green.opacity(0.4) : Color.blue.opacity(0.4), radius: 6, x: 0, y: 2)
    }

    // ✅ Propriétés calculées pour les couleurs
    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .gray
    }

    private var logoBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.9)
    }

    private var titleColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var buttonBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(cardBorderColor, lineWidth: 1)
            )
            .shadow(color: cardShadowColor, radius: 4, x: 0, y: 2)
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.08) : .white
    }

    private var cardBorderColor: Color {
        if isPlaying {
            return Color.blue.opacity(0.3)
        } else if isCustom {
            return Color.blue.opacity(0.2)
        } else if colorScheme == .light {
            return Color.black.opacity(0.1)
        }
        return .clear
    }

    private var cardShadowColor: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.05)
    }
}

// Extensions
extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

// Vues helpers
struct InitialLoadingView: View {
    @Environment(\.colorScheme) var colorScheme

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
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .blue))
                    .scaleEffect(1.3)

                Text("Chargement...")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "wifi.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("Connexion impossible")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)

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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: searchText.isEmpty ? "radio" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(emptyTitle)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)

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
