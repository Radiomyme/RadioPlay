//
//  NativeAdStationCard.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 05/10/2025.
//

import SwiftUI
import GoogleMobileAds

struct NativeAdStationCard: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var adLoader = NativeAdLoader()

    private var cardPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12
    }

    var body: some View {
        if let nativeAd = adLoader.nativeAd {
            GADNativeAdViewRepresentable(nativeAd: nativeAd)
                .frame(height: 80)
        }
    }
}

// MARK: - Native Ad Loader

class NativeAdLoader: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published var nativeAd: NativeAd?

    private var adLoader: AdLoader?

    override init() {
        super.init()
        loadAd()
    }

    func loadAd() {
        guard AppSettings.enableAds else { return }

        let adUnitID = AdMobManager.AdUnitIDs.native

        if let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController {

            adLoader = AdLoader(
                adUnitID: adUnitID,
                rootViewController: rootViewController,
                adTypes: [.native],
                options: nil
            )
            adLoader?.delegate = self
            adLoader?.load(AdMobManager.shared.createRequest())
        }
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        Logger.log("Native ad loaded successfully", category: .network, type: .default)
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        Logger.log("Native ad failed to load: \(error.localizedDescription)", category: .network, type: .error)
    }
}

// MARK: - GADNativeAdView Wrapper

struct GADNativeAdViewRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        adView.nativeAd = nativeAd

        // Configuration du fond de l'adView
        adView.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.08, alpha: 1.0)
                : .white
        }
        adView.layer.cornerRadius = 14
        adView.clipsToBounds = false

        // Border
        adView.layer.borderWidth = 1
        adView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor

        // Shadow (plus visible)
        adView.layer.shadowColor = UIColor.black.cgColor
        adView.layer.shadowOpacity = 0.1
        adView.layer.shadowOffset = CGSize(width: 0, height: 2)
        adView.layer.shadowRadius = 4

        // ===== Création des éléments de l'annonce =====

        // Headline (titre)
        let headlineView = UILabel()
        headlineView.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        headlineView.numberOfLines = 1
        headlineView.translatesAutoresizingMaskIntoConstraints = false
        headlineView.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }

        // Body (description)
        let bodyView = UILabel()
        bodyView.font = UIFont.systemFont(ofSize: 13)
        bodyView.numberOfLines = 2
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.textColor = .systemGray

        // Call to Action (bouton)
        let callToActionView = UIButton(type: .system)
        callToActionView.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        callToActionView.titleLabel?.adjustsFontSizeToFitWidth = true
        callToActionView.titleLabel?.minimumScaleFactor = 0.8
        callToActionView.titleLabel?.numberOfLines = 1
        callToActionView.setTitleColor(.white, for: .normal)
        callToActionView.backgroundColor = .systemBlue
        callToActionView.layer.cornerRadius = 20
        callToActionView.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        callToActionView.translatesAutoresizingMaskIntoConstraints = false
        callToActionView.setContentHuggingPriority(.required, for: .horizontal)
        callToActionView.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Icon (icône de l'annonceur)
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.backgroundColor = .clear
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // ✅ OBLIGATOIRE: Badge "Ad" (Ad Attribution)
        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 4
        adBadge.layer.masksToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false

        // ✅ OBLIGATOIRE: AdChoices (icône info en haut à droite)
        let adChoicesView = AdChoicesView()
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false

        // ===== Association des vues à l'AdView =====
        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.callToActionView = callToActionView
        adView.iconView = iconView
        adView.adChoicesView = adChoicesView

        // ===== Layout avec UIStackView =====

        // Conteneur pour l'icône
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = .clear
        iconContainer.addSubview(iconView)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 56),
            iconContainer.heightAnchor.constraint(equalToConstant: 56),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Stack horizontal pour headline + badge "Ad"
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(headlineView)
        headerStack.addArrangedSubview(adBadge)

        // Stack vertical pour headline + body
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(headerStack)
        textStack.addArrangedSubview(bodyView)

        // Stack principal horizontal
        let mainStack = UIStackView()
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(iconContainer)
        mainStack.addArrangedSubview(textStack)
        mainStack.addArrangedSubview(callToActionView)

        // Ajout à la vue
        adView.addSubview(mainStack)
        adView.addSubview(adChoicesView)

        // Forcer le rafraîchissement du contenu après l'assignation
        DispatchQueue.main.async {
            headlineView.text = nativeAd.headline
            bodyView.text = nativeAd.body
            if let callToAction = nativeAd.callToAction {
                callToActionView.setTitle(callToAction, for: .normal)
            }
            if let icon = nativeAd.icon {
                iconView.image = icon.image
            }
        }

        // ===== Contraintes =====
        NSLayoutConstraint.activate([
            // Stack principal
            mainStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            mainStack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),

            // Badge "Ad"
            adBadge.widthAnchor.constraint(equalToConstant: 28),
            adBadge.heightAnchor.constraint(equalToConstant: 16),

            // Text stack (flexible pour laisser de la place au bouton)
            textStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            // Call to Action button (peut grandir si besoin)
            callToActionView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            callToActionView.widthAnchor.constraint(lessThanOrEqualToConstant: 150),

            // ✅ AdChoices en haut à droite (position obligatoire)
            adChoicesView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 4),
            adChoicesView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -4),
            adChoicesView.widthAnchor.constraint(equalToConstant: 15),
            adChoicesView.heightAnchor.constraint(equalToConstant: 15)
        ])

        return adView
    }

    func updateUIView(_ uiView: NativeAdView, context: Context) {
        // Pas de mise à jour dynamique nécessaire
    }
}
