import Foundation
import Combine
import CoreData

class StationsViewModel: ObservableObject {
    @Published var stations: [Station] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var favoriteStations: [Station] = []
    @Published var isInitialLoadComplete = false

    private let favoritesRepository = FavoritesRepository()
    private let stationsRepository = StationsRepository()
    private let customStationsRepository = CustomStationsRepository()

    init() {
        loadCachedStationsSync()
        loadCustomStations()
    }

    // MARK: - Load Cached Stations

    private func loadCachedStationsSync() {
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
                        categories: entity.categories as? [String]
                    )
                }
                loadFavoriteStations()
            }
        } catch {
            Logger.log("Failed to load cached stations: \(error)", category: .database, type: .error)
        }
    }

    // MARK: - Load Custom Stations

    private func loadCustomStations() {
        let customStations = customStationsRepository.getCustomStations()
        let customStationsAsStations = customStations.map { $0.toStation() }
        stations.append(contentsOf: customStationsAsStations)
    }

    // MARK: - Load Stations from Network

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
                self.isInitialLoadComplete = true
                self.loadFavoriteStations()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Impossible de charger les stations: \(error.localizedDescription)"
                self.isLoading = false
                self.isInitialLoadComplete = true
            }
        }
    }

    // MARK: - Favorites Management

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

    // MARK: - Categories

    func getStationsByCategory(category: String) -> [Station] {
        if category.lowercased() == "all" || category.lowercased() == "toutes" {
            return stations
        } else if category.lowercased() == "favorites" || category.lowercased() == "favoris" {
            return favoriteStations
        } else {
            return stations.filter { station in
                if let categories = station.categories {
                    return categories.contains { $0.lowercased() == category.lowercased() }
                }
                return station.name.lowercased().contains(category.lowercased()) ||
                       station.subtitle.lowercased().contains(category.lowercased())
            }
        }
    }

    // MARK: - Custom Stations

    func addCustomStation(_ customStation: CustomStation) {
        customStationsRepository.addCustomStation(customStation)
        stations.append(customStation.toStation())
    }

    func removeCustomStation(_ stationId: String) {
        customStationsRepository.removeCustomStation(stationId)
        stations.removeAll { $0.id == stationId }
    }

    func isCustomStation(_ stationId: String) -> Bool {
        return customStationsRepository.isCustomStation(stationId)
    }
}
