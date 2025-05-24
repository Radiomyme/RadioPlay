//
//  StationsView mise à jour pour l'AudioManager
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


import SwiftUI

struct StationsView: View {
    @StateObject private var viewModel = StationsViewModel()
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @State private var searchText = ""
    @State private var selectedCategory: StationCategory = .all
    @State private var showSettings = false

    enum StationCategory: String, CaseIterable {
        case all = "Toutes"
        case favorites = "Favoris"
        case news = "Actualités"
        case music = "Musique"
        case sport = "Sport"
        case culture = "Culture"
    }

    var filteredStations: [Station] {
        // Première étape : appliquer le filtre de recherche
        let searchFiltered = searchText.isEmpty ?
            viewModel.stations :
            viewModel.stations.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
            }

        // Deuxième étape : appliquer le filtre de catégorie
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
                LinearGradient(gradient:
                    Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // En-tête personnalisé
                    HStack {
                        Text("Radio Play")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        // Bouton des paramètres
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Barre de recherche
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Rechercher une station", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color(white: 0.15))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 16)

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        Spacer()
                        VStack {
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .padding()

                            Button("Réessayer") {
                                Task {
                                    await viewModel.loadStations()
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Spacer()
                    } else {
                        // Catégories
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(StationCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        title: category.rawValue,
                                        isSelected: selectedCategory == category,
                                        action: {
                                            selectedCategory = category
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }

                        // Liste de stations - version standard verticale
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredStations) { station in
                                    Button(action: {
                                        handleStationTap(station)
                                    }) {
                                        ModernStationCard(
                                            station: station,
                                            isFavorite: viewModel.isFavorite(station: station),
                                            isPlaying: audioManager.currentStation?.id == station.id && audioManager.isPlaying,
                                            onFavoriteToggle: {
                                                viewModel.toggleFavorite(station: station)
                                            },
                                            onPlayToggle: {
                                                handleStationTap(station)
                                            }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }

                // Ajouter la vue Settings comme une feuille modale
                if showSettings {
                    SettingsView(isPresented: $showSettings)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .navigationBarHidden(true)
            .task {
                if viewModel.stations.isEmpty {
                    await viewModel.loadStations()
                }
            }
            .refreshable {
                await viewModel.loadStations()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // Gérer la lecture directement depuis la liste
    private func handleStationTap(_ station: Station) {
        if audioManager.currentStation?.id == station.id {
            // Si c'est la même station, toggle play/pause
            audioManager.togglePlayPause()
        } else {
            // Sinon, lancer la lecture de la nouvelle station
            audioManager.play(station: station)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    // État pour une animation au toucher
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(white: 0.15))
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                )
                .foregroundColor(isSelected ? .white : .gray)
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

// Extension pour capturer les gestes de pression
extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
    }
}

struct ModernStationCard: View {
    let station: Station
    let isFavorite: Bool
    let isPlaying: Bool
    let onFavoriteToggle: () -> Void
    let onPlayToggle: () -> Void

    var body: some View {
        ZStack {
            // Contenu principal de la carte
            HStack(spacing: 15) {
                // Logo de la station avec effet d'ombre
                AsyncImage(url: URL(string: station.logoURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.2))
                            .frame(width: 70, height: 70)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.2))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "radio")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(15)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(station.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)

                    Text(station.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)

                    // Ajouter un tag si c'est en direct (optionnel)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isPlaying ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(isPlaying ? "En écoute" : "En direct")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    // Bouton pour les favoris
                    Button(action: {
                        onFavoriteToggle()
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Bouton de lecture
                    Button(action: {
                        onPlayToggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isPlaying ? .green : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPlaying ? Color(white: 0.15) : Color(white: 0.1))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 2)
    }
}
