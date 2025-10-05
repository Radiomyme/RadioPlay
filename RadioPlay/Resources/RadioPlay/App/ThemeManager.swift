import SwiftUI
import UIKit

// Gestionnaire de thème centralisé pour l'application
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    // ✅ Par défaut en mode sombre
    @Published var isDarkMode: Bool {
        didSet {
            // Sauvegarder dans UserDefaults
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            // Appliquer le thème
            applyTheme()
        }
    }

    @Published var useSystemTheme: Bool {
        didSet {
            // Sauvegarder dans UserDefaults
            UserDefaults.standard.set(useSystemTheme, forKey: "useSystemTheme")
            // Appliquer le thème
            applyTheme()
        }
    }

    private init() {
        // Charger les préférences sauvegardées
        self.isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
        self.useSystemTheme = UserDefaults.standard.object(forKey: "useSystemTheme") as? Bool ?? false

        // Appliquer le thème au démarrage
        applyTheme()
    }

    func applyTheme() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Méthode moderne pour iOS 15+ pour accéder aux fenêtres de l'application
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    if self.useSystemTheme {
                        // Utiliser le thème système
                        window.overrideUserInterfaceStyle = .unspecified
                    } else {
                        // Forcer le thème choisi
                        window.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
                    }
                }
            }

            print("🎨 Thème appliqué: \(self.isDarkMode ? "Sombre" : "Clair"), Système: \(self.useSystemTheme)")
        }
    }

    func setDarkMode(_ enabled: Bool) {
        // Désactiver le thème système si on change manuellement
        if useSystemTheme {
            useSystemTheme = false
        }
        isDarkMode = enabled
    }

    func enableSystemTheme() {
        useSystemTheme = true

        // Détecter le thème système actuel pour mettre à jour l'état
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            isDarkMode = window.traitCollection.userInterfaceStyle == .dark
        }
    }
}
