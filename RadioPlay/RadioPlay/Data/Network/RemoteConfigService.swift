//
//  RemoteConfigService.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Data/Network/RemoteConfigService.swift
import Foundation

class RemoteConfigService {
    private let endpoint = "https://votre-domaine.com/api/stations"
    // Pour les tests, vous pouvez héberger un fichier JSON sur GitHub Gist ou Firebase
    
    func fetchStations() async throws -> [Station] {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            return try JSONDecoder().decode([Station].self, from: data)
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw NetworkError.decodingError
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}