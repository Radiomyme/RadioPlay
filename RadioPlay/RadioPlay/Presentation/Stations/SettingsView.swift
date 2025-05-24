//
//  SettingsView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme

    // Observer le ThemeManager
    @ObservedObject private var themeManager = ThemeManager.shared

    // Pour les animations
    @State private var appearAnimation = false

    // Pour les infos de version
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    @State private var showCellularAlert = false

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
                                    Image("default_artwork") // Logo de l'app
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

                        // Options de thème - Utilisant ThemeManager
                        GroupBox {
                            VStack(spacing: 16) {
                                Toggle("Mode sombre", isOn: $themeManager.isDarkMode)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))

                                Divider()

                                Button(action: {
                                    // Utiliser le thème système via ThemeManager
                                    themeManager.useSystemTheme()
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

                        // Paramètres audio
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Qualité de streaming")
                                    Spacer()
                                    Picker("", selection: .constant("Haute")) {
                                        Text("Haute").tag("Haute")
                                        Text("Moyenne").tag("Moyenne")
                                        Text("Basse").tag("Basse")
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(.blue)
                                }

                                Divider()

                                Button(action: {
                                    // Demander avant d'utiliser les données cellulaires
                                    showCellularAlert = true
                                }) {
                                    HStack {
                                        Text("Autoriser la 4G/5G")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                        } label: {
                            Label("Audio", systemImage: "speaker.wave.3")
                                .font(.headline)
                        }
                        .alert(isPresented: $showCellularAlert) {
                            Alert(
                                title: Text("Utiliser les données cellulaires ?"),
                                message: Text("Voulez-vous autoriser l'utilisation des données cellulaires (4G/5G) pour le streaming ? Cela peut augmenter votre consommation de données."),
                                primaryButton: .default(Text("Autoriser")) {
                                    // Logique pour autoriser les données cellulaires
                                },
                                secondaryButton: .cancel(Text("Wi-Fi uniquement"))
                            )
                        }

                        // Crédits
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Développé par Martin Parmentier")
                                    .font(.subheadline)

                                Divider()

                                Text("Cette application utilise des API publiques pour accéder aux flux des stations de radio.")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Divider()

                                Button(action: {
                                    // Ouvrir les conditions d'utilisation
                                    if let url = URL(string: "https://example.com/terms") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Conditions d'utilisation")
                                        .foregroundColor(.blue)
                                }

                                Button(action: {
                                    // Ouvrir la politique de confidentialité
                                    if let url = URL(string: "https://example.com/privacy") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Politique de confidentialité")
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

                // Actions en bas
                VStack(spacing: 12) {
                    Button(action: {
                        // Partager l'application avec méthode moderne pour trouver le rootViewController
                        let activityVC = UIActivityViewController(activityItems: ["Découvrez Radio Play, l'application idéale pour écouter vos radios préférées ! https://apps.apple.com/app/radioplay"], applicationActivities: nil)

                        // Utiliser la méthode moderne pour iOS 15+ pour trouver le rootViewController
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.windows.first?.rootViewController {
                            rootVC.present(activityVC, animated: true)
                        }
                    }) {
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

                    Button(action: {
                        // Noter l'application
                        if let url = URL(string: "https://apps.apple.com/app/id") {
                            UIApplication.shared.open(url)
                        }
                    }) {
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

    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            appearAnimation = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Prévisualisation
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isPresented: .constant(true))
            .preferredColorScheme(.dark)
    }
}
