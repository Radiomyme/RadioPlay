import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    init(adUnitID: String = AdMobManager.AdUnitIDs.banner, adSize: AdSize = AdSizeBanner) {
        self.adUnitID = adUnitID
        self.adSize = adSize
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID

        // Trouver le rootViewController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootViewController
        }

        banner.delegate = context.coordinator
        banner.load(AdMobManager.shared.createRequest())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // Pas besoin de mise à jour
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            Logger.log("Banner ad loaded successfully", category: .network, type: .default)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            Logger.log("Banner ad failed to load: \(error.localizedDescription)", category: .network, type: .error)
        }
    }
}

// MARK: - Adaptive Banner

struct AdaptiveBannerAdView: View {
    @State private var adSize: AdSize = AdSizeBanner

    var body: some View {
        BannerAdView(adSize: adSize)
            .frame(height: adSize.size.height)
            .onAppear {
                updateAdSize()
            }
    }

    private func updateAdSize() {
        let frame = UIScreen.main.bounds
        let viewWidth = frame.size.width

        // Utiliser la nouvelle API adaptative
        if UIDevice.current.userInterfaceIdiom == .pad {
            adSize = AdSizeLeaderboard
        } else {
            adSize = portraitAnchoredAdaptiveBanner(width: viewWidth)
        }
    }
}
