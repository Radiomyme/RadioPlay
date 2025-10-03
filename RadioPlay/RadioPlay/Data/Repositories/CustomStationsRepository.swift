//
//  CustomStationsRepository.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 03/10/2025.
//


//
//  CustomStationsRepository.swift
//  RadioPlay
//
//  Created by Martin Parmentier
//

import Foundation

class CustomStationsRepository {
    private let customStationsKey = "custom_stations"
    
    // Récupérer toutes les stations personnalisées
    func getCustomStations() -> [CustomStation] {
        guard let data = UserDefaults.standard.data(forKey: customStationsKey),
              let stations = try? JSONDecoder().decode([CustomStation].self, from: data) else {
            return []
        }
        return stations
    }
    
    // Sauvegarder les stations personnalisées
    func saveCustomStations(_ stations: [CustomStation]) {
        if let encoded = try? JSONEncoder().encode(stations) {
            UserDefaults.standard.set(encoded, forKey: customStationsKey)
            print("✅ Saved \(stations.count) custom stations")
        }
    }
    
    // Ajouter une station
    func addCustomStation(_ station: CustomStation) {
        var stations = getCustomStations()
        stations.append(station)
        saveCustomStations(stations)
    }
    
    // Supprimer une station
    func removeCustomStation(_ stationId: String) {
        var stations = getCustomStations()
        stations.removeAll { $0.id == stationId }
        saveCustomStations(stations)
    }
    
    // Modifier une station
    func updateCustomStation(_ station: CustomStation) {
        var stations = getCustomStations()
        if let index = stations.firstIndex(where: { $0.id == station.id }) {
            stations[index] = station
            saveCustomStations(stations)
        }
    }
    
    // Vérifier si une station est personnalisée
    func isCustomStation(_ stationId: String) -> Bool {
        return getCustomStations().contains(where: { $0.id == stationId })
    }
}