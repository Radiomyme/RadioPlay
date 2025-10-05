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
            HStack(spacing: 12) {
                // Icône pub
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                // Contenu de la pub
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(nativeAd.headline ?? "Publicité")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(titleColor)
                            .lineLimit(1)
                        
                        Text("Ad")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(4)
                    }
                    
                    Text(nativeAd.body ?? "Sponsorisé")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Bouton CTA
                if let callToAction = nativeAd.callToAction {
                    Button(action: {}) {
                        Text(callToAction)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(cardPadding)
            .background(cardBackground)
            .overlay(
                GADNativeAdViewRepresentable(nativeAd: nativeAd)
                    .frame(width: 0, height: 0)
                    .hidden()
            )
        }
    }
    
    private var titleColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: cardShadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.08) : .white
    }
    
    private var cardShadowColor: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.05)
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
        return adView
    }
    
    func updateUIView(_ uiView: NativeAdView, context: Context) {
        // Pas de mise à jour nécessaire
    }
}
