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
            let loadedStations = await stationsRepository.loadStations()
            
            await MainActor.run {
                self.stations = loadedStations
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Impossible de charger les stations: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
