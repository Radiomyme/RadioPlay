//
//  ArtworkService.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Domain/Services/ArtworkService.swift
import Foundation
import UIKit

class ArtworkService {
    private let cache = NSCache<NSString, UIImage>()
    
    func fetchArtwork(for track: Track) async throws -> UIImage? {
        // Vérifier le cache
        let cacheKey = "\(track.artist)-\(track.title)" as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Créer la requête iTunes
        let query = "\(track.artist) \(track.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(query)&entity=song&limit=1"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
            
            if let firstResult = result.results.first,
               let artworkURLString = firstResult.artworkUrl100?.replacingOccurrences(of: "100x100", with: "600x600"),
               let artworkURL = URL(string: artworkURLString) {
                
                let (imageData, _) = try await URLSession.shared.data(from: artworkURL)
                if let image = UIImage(data: imageData) {
                    // Mettre en cache
                    cache.setObject(image, forKey: cacheKey)
                    return image
                }
            }
            
            return nil
        } catch {
            print("Error fetching artwork: \(error)")
            throw error
        }
    }
}