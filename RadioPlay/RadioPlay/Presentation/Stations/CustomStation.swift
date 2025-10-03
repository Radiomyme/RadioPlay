//
//  CustomStation.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 03/10/2025.
//


//
//  CustomStation.swift
//  RadioPlay
//
//  Created by Martin Parmentier
//

import Foundation

struct CustomStation: Codable, Identifiable {
    let id: String
    var name: String
    var subtitle: String
    var streamURL: String
    var logoURL: String?
    var categories: [String]?
    var isCustom: Bool = true  // ✅ Identifier les stations custom
    var createdAt: Date
    
    init(name: String, subtitle: String, streamURL: String, logoURL: String? = nil, categories: [String]? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.subtitle = subtitle
        self.streamURL = streamURL
        self.logoURL = logoURL
        self.categories = categories
        self.createdAt = Date()
    }
    
    // ✅ Convertir en Station standard
    func toStation() -> Station {
        return Station(
            id: id,
            name: name,
            subtitle: subtitle,
            streamURL: streamURL,
            imageURL: nil,
            logoURL: logoURL,
            categories: categories
        )
    }
}