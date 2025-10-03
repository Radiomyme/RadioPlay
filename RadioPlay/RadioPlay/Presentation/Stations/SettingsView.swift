import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme

    // Observer le ThemeManager
    @ObservedObject private var themeManager = ThemeManager.shared

    // États pour les fonctionnalités
    @AppStorage("streamQuality") private var streamQuality: StreamQuality = .high
    @AppStorage("allowCellularData") private var allowCellularData = false
    @State private var showCellularAlert = false
    @State private var showQualityPicker = false

    // Pour les animations
    @State private var appearAnimation = false

    // Pour les infos de version
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    enum StreamQuality: String, CaseIterable {
        case low = "Basse"
        case medium = "Moyenne"
        case high = "Haute"

        var bitrate: String {
            switch self {
            case .low: return "64 kbps"
            case .medium: return "128 kbps"
            case .high: return "256 kbps"
            }
        }
    }

    var body: some View {
        ZStack {
            // Fond semi-transparent
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Contenu du popup
            VStack(spacing: 0) {
                // En-tête
                ZStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismissWithAnimation()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }

                    Text("À propos")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Contenu principal
                ScrollView {
                    VStack(spacing: 20) {
                        // À propos de l'application
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image("default_artwork")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(12)

                                    VStack(alignment: .leading) {
                                        Text("Radio Play")
                                            .font(.headline)
                                        Text("Version \(appVersion) (\(buildNumber))")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()
                                }

                                Text("Votre application préférée pour écouter les radios FM françaises où que vous soyez !")
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                            .padding(.vertical, 8)
                        } label: {
                            Label("À propos", systemImage: "info.circle")
                                .font(.headline)
                        }

                        // Options de thème - Fonctionnel
                        GroupBox {
                            VStack(spacing: 16) {
                                Toggle("Mode sombre", isOn: Binding(
                                    get: { themeManager.isDarkMode },
                                    set: { newValue in
                                        themeManager.setDarkMode(newValue)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .blue))

                                Divider()

                                Button(action: {
                                    themeManager.enableSystemTheme()
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }) {
                                    Text("Utiliser le thème système")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        } label: {
                            Label("Apparence", systemImage: "paintbrush")
                                .font(.headline)
                        }

                        // Paramètres audio - Fonctionnel
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                // Qualité de streaming
                                Button(action: {
                                    showQualityPicker = true
                                }) {
                                    HStack {
                                        Text("Qualité de streaming")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(streamQuality.rawValue)")
                                            .foregroundColor(.blue)
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 14))
                                    }
                                }

                                Divider()

                                // Données cellulaires
                                Toggle("Autoriser la 4G/5G", isOn: $allowCellularData)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    .onChange(of: allowCellularData) { newValue in
                                        if newValue {
                                            showCellularAlert = true
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                            }
                        } label: {
                            Label("Audio", systemImage: "speaker.wave.3")
                                .font(.headline)
                        }
                        .alert("Utiliser les données cellulaires ?", isPresented: $showCellularAlert) {
                            Button("Autoriser", role: .none) {
                                allowCellularData = true
                            }
                            Button("Wi-Fi uniquement", role: .cancel) {
                                allowCellularData = false
                            }
                        } message: {
                            Text("L'utilisation des données cellulaires (4G/5G) pour le streaming peut augmenter votre consommation de données.")
                        }
                        .actionSheet(isPresented: $showQualityPicker) {
                            ActionSheet(
                                title: Text("Qualité de streaming"),
                                message: Text("Choisissez la qualité audio"),
                                buttons: StreamQuality.allCases.map { quality in
                                    .default(Text("\(quality.rawValue) (\(quality.bitrate))")) {
                                        streamQuality = quality
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                } + [.cancel(Text("Annuler"))]
                            )
                        }

                        // Crédits et liens - Fonctionnels
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Développé par Martin Parmentier")
                                    .font(.subheadline)

                                Divider()

                                Text("Cette application utilise des API publiques pour accéder aux flux des stations de radio.")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Divider()

                                // Liens fonctionnels
                                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                                    HStack {
                                        Text("Conditions d'utilisation")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.blue)
                                }

                                Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                                    HStack {
                                        Text("Politique de confidentialité")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        } label: {
                            Label("Mentions légales", systemImage: "doc.text")
                                .font(.headline)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

                // Actions en bas - Fonctionnelles
                VStack(spacing: 12) {
                    // Partager l'application
                    Button(action: shareApp) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Partager Radio Play")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    // Noter l'application
                    Button(action: rateApp) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Noter l'application")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.15))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground).opacity(0.05))
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .frame(width: min(UIScreen.main.bounds.width - 40, 400))
            .padding(.horizontal, 20)
            .scaleEffect(appearAnimation ? 1 : 0.8)
            .opacity(appearAnimation ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Fonctions

    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            appearAnimation = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }

    private func shareApp() {
        let shareText = "Découvrez Radio Play, l'application idéale pour écouter vos radios préférées ! 📻"
        let shareURL = URL(string: "https://apps.apple.com/app/radioplay")

        var items: [Any] = [shareText]
        if let url = shareURL {
            items.append(url)
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // Exclure certains types de partage
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .saveToCameraRoll
        ]

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Pour iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }

        // Feedback haptique
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func rateApp() {
        // URL pour noter l'app sur l'App Store
        // Remplacer APP_ID par votre vrai App Store ID
        if let url = URL(string: "https://apps.apple.com/app/idAPP_ID?action=write-review") {
            UIApplication.shared.open(url)
        }

        // Feedback haptique
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Prévisualisation
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isPresented: .constant(true))
            .preferredColorScheme(.dark)
    }
}
