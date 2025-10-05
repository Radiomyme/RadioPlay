import Foundation
import GoogleMobileAds

class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()

    @Published var isInitialized = false

    // MARK: - Ad Unit IDs

    struct AdUnitIDs {
        // IDs de test (à remplacer en production)
        static let bannerTest = "ca-app-pub-3940256099942544/2435281174"
        static let nativeTest = "ca-app-pub-3940256099942544/3986624511"

        // IDs de production (à configurer dans AppSettings)
        static var banner: String {
            #if DEBUG
            return bannerTest
            #else
            return AppSettings.adMobBannerID
            #endif
        }

        static var native: String {
            #if DEBUG
            return nativeTest
            #else
            return AppSettings.adMobNativeID
            #endif
        }
    }

    private override init() {
        super.init()
    }

    // MARK: - Initialization

    func initialize() {
        // Nouvelle API pour iOS 14+
        MobileAds.shared.start { [weak self] status in
            DispatchQueue.main.async {
                self?.isInitialized = true
                Logger.log("AdMob initialized successfully", category: .network, type: .default)
            }
        }
    }

    // MARK: - Request Configuration

    func createRequest() -> Request {
        let request = Request()
        return request
    }
}
