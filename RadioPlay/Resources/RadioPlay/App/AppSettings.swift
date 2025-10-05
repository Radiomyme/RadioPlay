//
//  AppSettings.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 05/10/2025.
//


import Foundation
import UIKit

struct AppSettings {
    static let shared = AppSettings()
    
    private init() {}
    
    // MARK: - App Information
    
    static let appName = "Radio Play"
    static let appStoreID = "YOUR_APP_STORE_ID"
    static let appStoreURL = "https://apps.apple.com/app/id\(appStoreID)"
    static let appReviewURL = "https://apps.apple.com/app/id\(appStoreID)?action=write-review"
    
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Remote Configuration
    
    static let remoteStationsURL = "https://radiomyme.fr/server/radio_stations.json"
    static let localStationsFileName = "RadioStations+Categories"
    
    // MARK: - API Endpoints
    
    static let iTunesSearchBaseURL = "https://itunes.apple.com/search"
    static let appleMusicSearchBaseURL = "https://music.apple.com/search"
    
    // MARK: - Audio Configuration
    
    enum StreamQuality: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var bitrate: String {
            switch self {
            case .low: return "64 kbps"
            case .medium: return "128 kbps"
            case .high: return "256 kbps"
            }
        }
        
        var localizedName: String {
            switch self {
            case .low: return NSLocalizedString("settings.quality.low", comment: "")
            case .medium: return NSLocalizedString("settings.quality.medium", comment: "")
            case .high: return NSLocalizedString("settings.quality.high", comment: "")
            }
        }
    }
    
    static let preferredForwardBufferDuration: TimeInterval = 15.0
    static let preferredIOBufferDuration: TimeInterval = 0.005
    static let preferredSampleRate: Double = 44100.0
    
    // MARK: - UI Configuration
    
    static let horizontalPadding: CGFloat = 16
    static let horizontalPaddingIPad: CGFloat = 40
    static let miniPlayerHeight: CGFloat = 64
    static let miniPlayerBottomPadding: CGFloat = 12
    static let artworkSize: CGFloat = 280
    static let logoSize: CGFloat = 56
    static let logoSizeIPad: CGFloat = 72
    
    // MARK: - UserDefaults Keys
    
    enum UserDefaultsKeys {
        static let favoriteStations = "user_favorite_stations"
        static let customStations = "custom_stations"
        static let isDarkMode = "isDarkMode"
        static let useSystemTheme = "useSystemTheme"
        static let streamQuality = "streamQuality"
        static let allowCellularData = "allowCellularData"
        static let selectedLanguage = "selectedLanguage"
    }
    
    // MARK: - Legal Links
    
    static let termsOfServiceURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let privacyPolicyURL = "https://www.apple.com/legal/privacy/"
    static let supportURL = "https://support.claude.com"
    
    // MARK: - Feature Flags
    
    static let enableCustomStations = true
    static let enableSleepTimer = true
    static let enableAirPlay = true
    static let enableShareFeature = true
    
    // MARK: - Localization
    
    enum SupportedLanguage: String, CaseIterable {
        case french = "fr"
        case english = "en"
        case spanish = "es"
        
        var displayName: String {
            switch self {
            case .french: return "Français"
            case .english: return "English"
            case .spanish: return "Español"
            }
        }
        
        var flag: String {
            switch self {
            case .french: return "🇫🇷"
            case .english: return "🇬🇧"
            case .spanish: return "🇪🇸"
            }
        }
    }
    
    static var currentLanguage: SupportedLanguage {
        get {
            if let savedLanguage = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedLanguage),
               let language = SupportedLanguage(rawValue: savedLanguage) {
                return language
            }
            
            let preferredLanguages = Locale.preferredLanguages
            if let firstLanguage = preferredLanguages.first {
                if firstLanguage.hasPrefix("fr") {
                    return .french
                } else if firstLanguage.hasPrefix("es") {
                    return .spanish
                }
            }
            return .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.selectedLanguage)
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: - Helper Methods
    
    static func horizontalPadding(for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) -> CGFloat {
        return device == .pad ? horizontalPaddingIPad : horizontalPadding
    }
    
    static func logoSize(for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) -> CGFloat {
        return device == .pad ? logoSizeIPad : logoSize
    }
}