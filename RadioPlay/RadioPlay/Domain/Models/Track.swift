//
//  Track.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


import Foundation

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String?
}