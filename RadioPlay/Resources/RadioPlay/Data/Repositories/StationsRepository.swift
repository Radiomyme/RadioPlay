import Foundation
import CoreData

class StationsRepository {
    private let remoteConfigService = RemoteConfigService()
    private let coreDataManager = CoreDataManager.shared

    // MARK: - Load Stations

    func loadStations() async throws -> [Station] {
        let localStations = fetchLocalStations()

        if localStations.isEmpty {
            do {
                if let stations = loadStationsFromLocalJSON() {
                    await saveStationsLocally(stations)
                    return stations
                }
            } catch {
                Logger.log("Local JSON loading error: \(error)", category: .database, type: .error)
            }
        }

        do {
            let remoteStations = try await remoteConfigService.fetchStations()
            await saveStationsLocally(remoteStations)
            return remoteStations
        } catch {
            Logger.log("Remote stations fetch failed: \(error)", category: .network, type: .error)

            if localStations.isEmpty {
                throw error
            }

            return localStations
        }
    }

    // MARK: - Local JSON

    private func loadStationsFromLocalJSON() -> [Station]? {
        guard let path = Bundle.main.path(
            forResource: AppSettings.localStationsFileName,
            ofType: "json"
        ) else {
            Logger.log("Local JSON file not found", category: .database, type: .error)
            return createDefaultStations()
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let stations = try JSONDecoder().decode([Station].self, from: data)
            return stations
        } catch {
            Logger.log("JSON decoding error: \(error)", category: .database, type: .error)
            return createDefaultStations()
        }
    }

    private func createDefaultStations() -> [Station] {
        return [
            Station(
                id: "1",
                name: "RTL",
                subtitle: "RTL bouge",
                streamURL: "https://streaming.radio.rtl.fr/rtl-1-44-96",
                imageURL: "https://cdn-media.rtl.fr/cache/LlH3G2yGy3FcB8JSqtN02g/1800x1200-0/online/image/rtl.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/RTL_logo.svg/1200px-RTL_logo.svg.png",
                categories: ["Actualités", "Généraliste"]
            ),
            Station(
                id: "2",
                name: "France Info",
                subtitle: "Actualités en temps réel",
                streamURL: "https://icecast.radiofrance.fr/franceinfo-midfi.mp3",
                imageURL: "https://cdn-media.rtl.fr/online/image/2015/0623/7778732219_franceinfo-logo.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/Franceinfo.svg/1200px-Franceinfo.svg.png",
                categories: ["Actualités", "Information"]
            ),
            Station(
                id: "3",
                name: "NRJ",
                subtitle: "Hit Music Only",
                streamURL: "https://scdn.nrjaudio.fm/audio1/fr/30001/mp3_128.mp3",
                imageURL: "https://cdn.nrjaudio.fm/adimg/6779/3535779/1900x1080_NRJ-Supernova_1.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/NRJ_logo_2019.svg/1200px-NRJ_logo_2019.svg.png",
                categories: ["Musique", "Pop"]
            )
        ]
    }

    // MARK: - CoreData Operations

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
