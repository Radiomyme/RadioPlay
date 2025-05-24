//
//  ThemeManager.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI

// Gestionnaire de thème centralisé pour l'application
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("isDarkMode") var isDarkMode: Bool = true {
        didSet {
            applyTheme()
        }
    }

    init() {
        // Appliquer le thème au démarrage
        applyTheme()
    }

    func applyTheme() {
        // Force l'application à utiliser le mode sombre ou clair
        DispatchQueue.main.async {
            // Méthode moderne pour iOS 15+ pour accéder aux fenêtres de l'application
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
                }
            }
        }
    }

    func useSystemTheme() {
        // Réinitialise au thème système
        DispatchQueue.main.async {
            // Méthode moderne pour iOS 15+
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }

            // Mettre à jour l'état local selon le système actuel
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                self.isDarkMode = window.traitCollection.userInterfaceStyle == .dark
            }
        }
    }

    // Méthode utilitaire pour déterminer l'état actuel du mode sombre au niveau du système
    func detectSystemTheme() -> Bool {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.traitCollection.userInterfaceStyle == .dark
        }
        return false
    }
}
