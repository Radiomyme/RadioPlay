//
//  LocalizationHelper.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 05/10/2025.
//

import Foundation
import SwiftUI

extension String {
    var localized: String {
        let language = LocalizationManager.shared.currentLanguage.rawValue

        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }

        return NSLocalizedString(self, bundle: bundle, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        let language = LocalizationManager.shared.currentLanguage.rawValue

        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
        }

        return String(format: NSLocalizedString(self, bundle: bundle, comment: ""), arguments: arguments)
    }
}

struct L10n {

    // MARK: - General
    struct General {
        static var loading: String { "general.loading".localized }
        static var retry: String { "general.retry".localized }
        static var cancel: String { "general.cancel".localized }
        static var delete: String { "general.delete".localized }
        static var close: String { "general.close".localized }
        static var save: String { "general.save".localized }
        static var search: String { "general.search".localized }
    }

    // MARK: - Navigation
    struct Nav {
        static var all: String { "nav.all".localized }
        static var favorites: String { "nav.favorites".localized }
        static var news: String { "nav.news".localized }
        static var music: String { "nav.music".localized }
        static var sport: String { "nav.sport".localized }
        static var culture: String { "nav.culture".localized }
    }

    // MARK: - Stations
    struct Stations {
        static var title: String { "stations.title".localized }
        static var searchPlaceholder: String { "stations.search.placeholder".localized }
        static var updating: String { "stations.updating".localized }
        static var playing: String { "stations.playing".localized }
        static var live: String { "stations.live".localized }
        static var customBadge: String { "stations.custom.badge".localized }
    }

    // MARK: - Empty States
    struct Empty {
        static var noResults: String { "empty.no_results".localized }
        static var tryAnotherSearch: String { "empty.try_another_search".localized }
        static var noFavorites: String { "empty.no_favorites".localized }
        static var addFavoritesMessage: String { "empty.add_favorites_message".localized }
        static var noStations: String { "empty.no_stations".localized }
        static var noStationsCategory: String { "empty.no_stations_category".localized }
    }

    // MARK: - Errors
    struct Error {
        static var connectionFailed: String { "error.connection_failed".localized }
        static var noInternet: String { "error.no_internet".localized }
    }

    // MARK: - Player
    struct Player {
        static var buffering: String { "player.buffering".localized }

        static func shareMessage(track: String, artist: String, station: String) -> String {
            return "player.share_message".localized(with: track, artist, station)
        }
    }

    // MARK: - Sleep Timer
    struct SleepTimer {
        static var title: String { "sleep_timer.title".localized }
        static var selectDuration: String { "sleep_timer.select_duration".localized }
        static var remaining: String { "sleep_timer.remaining".localized }
        static var cancel: String { "sleep_timer.cancel".localized }
        static var hour: String { "sleep_timer.hour".localized }

        static func minutes(_ count: Int) -> String {
            return "sleep_timer.minutes".localized(with: count)
        }

        static func hours(_ count: Int) -> String {
            return "sleep_timer.hours".localized(with: count)
        }
    }

    // MARK: - Add Station
    struct AddStation {
        static var title: String { "add_station.title".localized }
        static var subtitle: String { "add_station.subtitle".localized }
        static var namePlaceholder: String { "add_station.name.placeholder".localized }
        static var sloganPlaceholder: String { "add_station.slogan.placeholder".localized }
        static var streamUrlPlaceholder: String { "add_station.stream_url.placeholder".localized }
        static var logoUrlPlaceholder: String { "add_station.logo_url.placeholder".localized }
        static var categories: String { "add_station.categories".localized }
        static var testStream: String { "add_station.test_stream".localized }
        static var testing: String { "add_station.testing".localized }
        static var validStream: String { "add_station.valid_stream".localized }
        static var helpText: String { "add_station.help_text".localized }
        static var button: String { "add_station.button".localized }
        static var deleteConfirm: String { "add_station.delete_confirm".localized }
        static var deleteMessage: String { "add_station.delete_message".localized }
    }

    // MARK: - Settings
    struct Settings {
        static var title: String { "settings.title".localized }
        static var about: String { "settings.about".localized }

        static func version(_ version: String, _ build: String) -> String {
            return "settings.version".localized(with: version, build)
        }

        static var description: String { "settings.description".localized }
        static var appearance: String { "settings.appearance".localized }
        static var darkMode: String { "settings.dark_mode".localized }
        static var systemTheme: String { "settings.system_theme".localized }
        static var audio: String { "settings.audio".localized }
        static var quality: String { "settings.quality".localized }
        static var cellular: String { "settings.cellular".localized }
        static var cellularAlertTitle: String { "settings.cellular_alert.title".localized }
        static var cellularAlertMessage: String { "settings.cellular_alert.message".localized }
        static var cellularAlertAllow: String { "settings.cellular_alert.allow".localized }
        static var cellularAlertWifiOnly: String { "settings.cellular_alert.wifi_only".localized }
        static var language: String { "settings.language".localized }
        static var languageTitle: String { "settings.language.title".localized }
        static var languageChangeNotice: String { "settings.language.change_notice".localized }
        static var legal: String { "settings.legal".localized }
        static var developer: String { "settings.developer".localized }
        static var apiNotice: String { "settings.api_notice".localized }
        static var terms: String { "settings.terms".localized }
        static var privacy: String { "settings.privacy".localized }
        static var shareApp: String { "settings.share_app".localized }
        static var rateApp: String { "settings.rate_app".localized }
        static var shareMessage: String { "settings.share_message".localized }
    }

    // MARK: - Quality
    struct Quality {
        static var low: String { "settings.quality.low".localized }
        static var medium: String { "settings.quality.medium".localized }
        static var high: String { "settings.quality.high".localized }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppSettings.SupportedLanguage {
        didSet {
            AppSettings.currentLanguage = currentLanguage
            updateLocale()
        }
    }

    private init() {
        self.currentLanguage = AppSettings.currentLanguage
    }

    private func updateLocale() {
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        objectWillChange.send()

        NotificationCenter.default.post(name: .languageDidChange, object: nil)

        print("🌐 Language changed to: \(currentLanguage.displayName)")
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
