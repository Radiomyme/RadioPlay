//
//  NetworkError.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Data/Network/NetworkError.swift
import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(Int)
    case unknown(Error)
}