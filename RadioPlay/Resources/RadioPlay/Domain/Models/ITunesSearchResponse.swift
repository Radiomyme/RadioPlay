//
//  ITunesSearchResponse.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Domain/Models/ITunesModels.swift
import Foundation

struct ITunesSearchResponse: Decodable {
    let resultCount: Int
    let results: [ITunesTrack]
}

struct ITunesTrack: Decodable {
    let trackName: String?
    let artistName: String?
    let collectionName: String?
    let artworkUrl100: String?
    let trackViewUrl: String?
}