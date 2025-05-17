//
//  StationsViewModel.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Stations/StationsViewModel.swift
import Foundation
import Combine

class StationsViewModel: ObservableObject {
    @Published var stations: [Station] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var favoriteStations: [Station] = []

    private let favoritesRepository = FavoritesRepository()
    private let stationsRepository = StationsRepository()

    func loadStations() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let loadedStations = try await stationsRepository.loadStations()

            await MainActor.run {
                self.stations = loadedStations
                self.isLoading = false
                // Charger aussi les favoris
                self.loadFavoriteStations()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Impossible de charger les stations: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // Méthodes pour gérer les favoris
    func loadFavoriteStations() {
        let favoriteIds = favoritesRepository.getFavorites()
        favoriteStations = stations.filter { station in
            favoriteIds.contains(station.id)
        }
    }

    func toggleFavorite(station: Station) {
        if favoritesRepository.isFavorite(station.id) {
            favoritesRepository.removeFavorite(station.id)
        } else {
            favoritesRepository.addFavorite(station.id)
        }
        loadFavoriteStations()
    }

    func isFavorite(station: Station) -> Bool {
        return favoritesRepository.isFavorite(station.id)
    }
}
