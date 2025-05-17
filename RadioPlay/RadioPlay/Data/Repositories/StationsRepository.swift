//
//  StationsRepository.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Data/Repositories/StationsRepository.swift
import Foundation
import CoreData

class StationsRepository {
    private let remoteConfigService = RemoteConfigService()
    private let coreDataManager = CoreDataManager.shared
    
    // Charger les stations (d'abord localement, puis tenter de mettre à jour depuis le réseau)
    func loadStations() async throws -> [Station] {
        let localStations = fetchLocalStations()

        do {
            // Tenter de récupérer les stations à distance
            let remoteStations = try await remoteConfigService.fetchStations()

            // Si on a réussi, mettre à jour le stockage local
            await saveStationsLocally(remoteStations)
            return remoteStations
        } catch {
            Logger.log("Failed to fetch remote stations: \(error)", category: .network, type: .error)

            // Si nous n'avons pas de stations locales non plus, remonter l'erreur
            if localStations.isEmpty {
                throw error
            }

            // Renvoyer les stations locales si la récupération à distance échoue
            return localStations
        }
    }

    // Récupérer les stations stockées localement
    private func fetchLocalStations() -> [Station] {
        let context = coreDataManager.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<StationEntity> = StationEntity.fetchRequest()
        
        do {
            let stationEntities = try context.fetch(fetchRequest)
            return stationEntities.map { entity in
                Station(
                    id: entity.id ?? UUID().uuidString,
                    name: entity.name ?? "",
                    subtitle: entity.subtitle ?? "",
                    streamURL: entity.streamURL ?? "",
                    imageURL: entity.imageURL,
                    logoURL: entity.logoURL
                )
            }
        } catch {
            print("Failed to fetch local stations: \(error)")
            return []
        }
    }
    
    // Sauvegarder les stations localement
    private func saveStationsLocally(_ stations: [Station]) async {
        // S'exécuter sur un thread d'arrière-plan pour éviter de bloquer l'UI
        await MainActor.run {
            let context = coreDataManager.persistentContainer.viewContext
            
            // Supprimer les stations existantes
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StationEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                
                // Ajouter les nouvelles stations
                for station in stations {
                    let entity = StationEntity(context: context)
                    entity.id = station.id
                    entity.name = station.name
                    entity.subtitle = station.subtitle
                    entity.streamURL = station.streamURL
                    entity.imageURL = station.imageURL
                    entity.logoURL = station.logoURL
                }
                
                coreDataManager.saveContext()
            } catch {
                print("Failed to save stations locally: \(error)")
            }
        }
    }
}
