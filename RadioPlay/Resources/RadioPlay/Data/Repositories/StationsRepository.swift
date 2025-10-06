import Foundation
import CoreData
import os

class StationsRepository {
    private let remoteConfigService = RemoteConfigService()
    private let coreDataManager = CoreDataManager.shared

    func loadStations() async throws -> [Station] {
        do {
            let remoteStations = try await remoteConfigService.fetchStations()
            await saveStationsLocally(remoteStations)
            Logger.log("Stations loaded from remote server", category: .network, type: .default)
            return remoteStations
        } catch {
            Logger.log("Remote fetch failed: \(error.localizedDescription)", category: .network, type: .error)
        }

        let cachedStations = fetchLocalStations()
        if !cachedStations.isEmpty {
            Logger.log("Stations loaded from CoreData cache", category: .database, type: .default)
            return cachedStations
        }

        if let localStations = loadStationsFromLocalJSON() {
            await saveStationsLocally(localStations)
            Logger.log("Stations loaded from local JSON fallback", category: .database, type: .default)
            return localStations
        }

        let defaultStations = createDefaultStations()
        await saveStationsLocally(defaultStations)
        Logger.log("Using default hardcoded stations", category: .database, type: .error)
        return defaultStations
    }

    private func loadStationsFromLocalJSON() -> [Station]? {
        guard let path = Bundle.main.path(
            forResource: AppSettings.localStationsFileName,
            ofType: "json"
        ) else {
            Logger.log("Local JSON file not found", category: .database, type: .error)
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let stations = try JSONDecoder().decode([Station].self, from: data)
            return stations
        } catch {
            Logger.log("JSON decoding error: \(error)", category: .database, type: .error)
            return nil
        }
    }

    private func createDefaultStations() -> [Station] {
        return [
            Station(
                id: "1",
                name: "RTL",
                subtitle: "Toujours avec vous",
                streamURL: "https://icecast.rtl.fr/rtl-1-44-128",
                imageURL: "https://cdn-media.rtl.fr/cache/LlH3G2yGy3FcB8JSqtN02g/1800x1200-0/online/image/rtl.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/RTL_logo.svg/1200px-RTL_logo.svg.png",
                categories: ["news"]
            ),
            Station(
                id: "2",
                name: "France Info",
                subtitle: "Vivons bien informés",
                streamURL: "https://icecast.radiofrance.fr/franceinfo-midfi.mp3",
                imageURL: "https://www.francetvpub.fr/sites/default/files/styles/image_768x432/public/2023-10/FI_home_logo_0.png",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/Franceinfo.svg/1200px-Franceinfo.svg.png",
                categories: ["news"]
            ),
            Station(
                id: "3",
                name: "NRJ",
                subtitle: "Hit Music Only",
                streamURL: "https://scdn.nrjaudio.fm/audio1/fr/30001/mp3_128.mp3",
                imageURL: "https://cdn.nrjaudio.fm/adimg/6779/3535779/1900x1080_NRJ-Supernova_1.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/NRJ_logo_2019.svg/1200px-NRJ_logo_2019.svg.png",
                categories: ["music"]
            )
        ]
    }

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
                    logoURL: entity.logoURL,
                    categories: entity.categories as? [String]
                )
            }
        } catch {
            Logger.log("CoreData fetch failed: \(error)", category: .database, type: .error)
            return []
        }
    }

    private func saveStationsLocally(_ stations: [Station]) async {
        await MainActor.run {
            let context = coreDataManager.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StationEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)

                for station in stations {
                    let entity = StationEntity(context: context)
                    entity.id = station.id
                    entity.name = station.name
                    entity.subtitle = station.subtitle
                    entity.streamURL = station.streamURL
                    entity.imageURL = station.imageURL
                    entity.logoURL = station.logoURL

                    if let categories = station.categories {
                        entity.categories = categories as [String]
                    }
                }

                coreDataManager.saveContext()
            } catch {
                Logger.log("CoreData save failed: \(error)", category: .database, type: .error)
            }
        }
    }
}
