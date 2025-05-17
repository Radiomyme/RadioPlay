//
//  FavoritesRepository.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Data/Repositories/FavoritesRepository.swift
import Foundation

class FavoritesRepository {
    private let favoritesKey = "user_favorite_stations"

    func getFavorites() -> [String] {
        return UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }

    func saveFavorites(_ stationIds: [String]) {
        UserDefaults.standard.set(stationIds, forKey: favoritesKey)
    }

    func addFavorite(_ stationId: String) {
        var favorites = getFavorites()
        if !favorites.contains(stationId) {
            favorites.append(stationId)
            saveFavorites(favorites)
        }
    }

    func removeFavorite(_ stationId: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == stationId }
        saveFavorites(favorites)
    }

    func isFavorite(_ stationId: String) -> Bool {
        return getFavorites().contains(stationId)
    }
}
