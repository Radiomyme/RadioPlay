//
//  Station.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


import Foundation

struct Station: Identifiable, Decodable {
    let id: String
    let name: String
    let subtitle: String
    let streamURL: String
    let imageURL: String?
    let logoURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "radioName"
        case subtitle = "radioSubtitle"
        case streamURL = "radioStreamURL"
        case imageURL = "backgroundImage"
        case logoURL = "radioLogo"
    }
}

extension Station: Equatable {
    static func == (lhs: Station, rhs: Station) -> Bool {
        return lhs.id == rhs.id
    }
}
