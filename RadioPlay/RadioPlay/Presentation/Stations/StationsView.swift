//
//  StationsView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Stations/StationsView.swift
import SwiftUI

struct StationsView: View {
    @StateObject private var viewModel = StationsViewModel()
    @State private var searchText = ""

    var filteredStations: [Station] {
        if searchText.isEmpty {
            return viewModel.stations
        } else {
            return viewModel.stations.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
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

                        // Bouton des paramètres (à implémenter)
                        Button(action: {
                            // Action pour les paramètres
                        }) {
                            Image(systemName: "gearshape.fill")
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
                                CategoryChip(title: "Toutes", isSelected: true)
                                CategoryChip(title: "Favoris", isSelected: false)
                                CategoryChip(title: "Actualités", isSelected: false)
                                CategoryChip(title: "Musique", isSelected: false)
                                CategoryChip(title: "Sport", isSelected: false)
                                CategoryChip(title: "Culture", isSelected: false)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }

                        // Liste de stations
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredStations) { station in
                                    NavigationLink(destination: PlayerView(station: station)) {
                                        ModernStationCard(station: station, isFavorite: viewModel.isFavorite(station: station))
                                            .onTapGesture {
                                                // Vide car NavigationLink gère le tap
                                            }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
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
        .preferredColorScheme(.dark)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(white: 0.15))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
    }
}

struct ModernStationCard: View {
    let station: Station
    let isFavorite: Bool

    var body: some View {
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
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("En direct")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                // Indicateur de favori
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .gray)

                // Bouton de lecture
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 2)
    }
}
