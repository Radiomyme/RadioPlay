//
//  StationsViewModel.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


import Foundation
import Combine
import CoreData

class StationsViewModel: ObservableObject {
    @Published var stations: [Station] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var favoriteStations: [Station] = []
    @Published var hasInitiallyLoaded = false

    private let favoritesRepository = FavoritesRepository()
    private let stationsRepository = StationsRepository()
    private let customStationsRepository = CustomStationsRepository()  // ✅ NOUVEAU

    init() {
        loadCachedStationsSync()
        loadCustomStations()  // ✅ NOUVEAU
    }

    // ✅ NOUVEAU - Charger les stations personnalisées
    private func loadCustomStations() {
        let customStations = customStationsRepository.getCustomStations()
        let customStationsAsStations = customStations.map { $0.toStation() }

        // Fusionner avec les stations existantes
        stations.append(contentsOf: customStationsAsStations)
    }

    // ✅ NOUVEAU - Ajouter une station personnalisée
    func addCustomStation(_ customStation: CustomStation) {
        customStationsRepository.addCustomStation(customStation)
        stations.append(customStation.toStation())
        print("✅ Station personnalisée ajoutée: \(customStation.name)")
    }

    // ✅ NOUVEAU - Supprimer une station personnalisée
    func removeCustomStation(_ stationId: String) {
        customStationsRepository.removeCustomStation(stationId)
        stations.removeAll { $0.id == stationId }
    }

    // ✅ NOUVEAU - Vérifier si une station est personnalisée
    func isCustomStation(_ stationId: String) -> Bool {
        return customStationsRepository.isCustomStation(stationId)
    }

    // ✅ NOUVEAU - Charger les stations en cache de manière synchrone
    private func loadCachedStationsSync() {
        // Charger immédiatement les stations depuis CoreData
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<StationEntity> = StationEntity.fetchRequest()

        do {
            let stationEntities = try context.fetch(fetchRequest)
            if !stationEntities.isEmpty {
                self.stations = stationEntities.map { entity in
                    Station(
                        id: entity.id ?? UUID().uuidString,
                        name: entity.name ?? "",
                        subtitle: entity.subtitle ?? "",
                        streamURL: entity.streamURL ?? "",
                        imageURL: entity.imageURL,
                        logoURL: entity.logoURL,
                        categories: entity.categories as? [String]  // ✅ Cast sécurisé
                    )
                }
                self.hasInitiallyLoaded = true
                loadFavoriteStations()
            }
        } catch {
            print("Failed to load cached stations: \(error)")
        }
    }

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
                self.hasInitiallyLoaded = true  // ✅ Marqué comme chargé
                self.loadFavoriteStations()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Impossible de charger les stations: \(error.localizedDescription)"
                self.isLoading = false
                // ✅ Même en cas d'erreur, on a essayé
                self.hasInitiallyLoaded = true
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

    // Nouvelles méthodes pour les catégories
    func getStationsByCategory(category: String) -> [Station] {
        // Filtre les stations par catégorie
        if category.lowercased() == "all" || category.lowercased() == "toutes" {
            return stations
        } else if category.lowercased() == "favorites" || category.lowercased() == "favoris" {
            return favoriteStations
        } else {
            // Recherche dans le tableau de catégories
            return stations.filter { station in
                if let categories = station.categories {
                    return categories.contains { $0.lowercased() == category.lowercased() }
                }
                // Si pas de catégories définies, on fait une recherche texte
                return station.name.lowercased().contains(category.lowercased()) ||
                       station.subtitle.lowercased().contains(category.lowercased())
            }
        }
    }
}
