import SwiftUI
import UIKit

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: AppSettings.UserDefaultsKeys.isDarkMode)
            applyTheme()
        }
    }

    @Published var useSystemTheme: Bool {
        didSet {
            UserDefaults.standard.set(useSystemTheme, forKey: AppSettings.UserDefaultsKeys.useSystemTheme)
            applyTheme()
        }
    }

    private init() {
        self.isDarkMode = UserDefaults.standard.object(forKey: AppSettings.UserDefaultsKeys.isDarkMode) as? Bool ?? true
        self.useSystemTheme = UserDefaults.standard.object(forKey: AppSettings.UserDefaultsKeys.useSystemTheme) as? Bool ?? false
        applyTheme()
    }

    // MARK: - Theme Application

    func applyTheme() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    if self.useSystemTheme {
                        window.overrideUserInterfaceStyle = .unspecified
                    } else {
                        window.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
                    }
                }
            }
        }
    }

    // MARK: - Theme Control

    func setDarkMode(_ enabled: Bool) {
        if useSystemTheme {
            useSystemTheme = false
        }
        isDarkMode = enabled
    }

    func enableSystemTheme() {
        useSystemTheme = true

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            isDarkMode = window.traitCollection.userInterfaceStyle == .dark
        }
    }
}
