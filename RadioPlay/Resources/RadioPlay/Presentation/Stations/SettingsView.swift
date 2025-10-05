import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @AppStorage(AppSettings.UserDefaultsKeys.streamQuality) private var streamQuality: String = AppSettings.StreamQuality.high.rawValue
    @AppStorage(AppSettings.UserDefaultsKeys.allowCellularData) private var allowCellularData = false

    @State private var showCellularAlert = false
    @State private var showQualityPicker = false
    @State private var showLanguagePicker = false

    @State private var appearAnimation = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissWithAnimation()
                }

            VStack(spacing: 0) {
                header
                Divider().background(Color.gray.opacity(0.3))

                ScrollView {
                    VStack(spacing: 20) {
                        aboutSection
                        languageSection
                        appearanceSection
                        audioSection
                        legalSection
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

                actionButtons
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
        .alert(L10n.Settings.cellularAlertTitle, isPresented: $showCellularAlert) {
            Button(L10n.Settings.cellularAlertAllow, role: .none) {
                allowCellularData = true
            }
            Button(L10n.Settings.cellularAlertWifiOnly, role: .cancel) {
                allowCellularData = false
            }
        } message: {
            Text(L10n.Settings.cellularAlertMessage)
        }

        .actionSheet(isPresented: $showQualityPicker) {
            ActionSheet(
                title: Text(L10n.Settings.quality),
                message: Text(L10n.Settings.quality),
                buttons: AppSettings.StreamQuality.allCases.map { quality in
                    .default(Text("\(quality.localizedName) (\(quality.bitrate))")) {
                        streamQuality = quality.rawValue
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } + [.cancel(Text(L10n.General.cancel))]
            )
        }
        .actionSheet(isPresented: $showLanguagePicker) {
            ActionSheet(
                title: Text(L10n.Settings.languageTitle),
                buttons: AppSettings.SupportedLanguage.allCases.map { language in
                    .default(Text("\(language.flag) \(language.displayName)")) {
                        localizationManager.currentLanguage = language
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } + [.cancel(Text(L10n.General.cancel))]
            )
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: { dismissWithAnimation() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }

            Text(L10n.Settings.title)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
    }

    private var aboutSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image("default_artwork")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)

                    VStack(alignment: .leading) {
                        Text(AppSettings.appName)
                            .font(.headline)
                        Text(L10n.Settings.version(AppSettings.appVersion, AppSettings.buildNumber))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }

                Text(L10n.Settings.description)
                    .font(.body)
                    .padding(.top, 4)
            }
            .padding(.vertical, 8)
        } label: {
            Label(L10n.Settings.about, systemImage: "info.circle")
                .font(.headline)
        }
    }

    private var languageSection: some View {
        GroupBox {
            Button(action: { showLanguagePicker = true }) {
                HStack {
                    Text(L10n.Settings.language)
                        .foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 8) {
                        Text(localizationManager.currentLanguage.flag)
                        Text(localizationManager.currentLanguage.displayName)
                            .foregroundColor(.blue)
                    }
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
        } label: {
            Label(L10n.Settings.language, systemImage: "globe")
                .font(.headline)
        }
    }

    private var appearanceSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                Toggle(L10n.Settings.darkMode, isOn: Binding(
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
                    Text(L10n.Settings.systemTheme)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        } label: {
            Label(L10n.Settings.appearance, systemImage: "paintbrush")
                .font(.headline)
        }
    }

    private var audioSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: { showQualityPicker = true }) {
                    HStack {
                        Text(L10n.Settings.quality)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(currentQualityDisplay)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                }

                Divider()

                Toggle(L10n.Settings.cellular, isOn: $allowCellularData)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: allowCellularData) { newValue in
                        if newValue {
                            showCellularAlert = true
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
            }
        } label: {
            Label(L10n.Settings.audio, systemImage: "speaker.wave.3")
                .font(.headline)
        }
    }

    private var legalSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Settings.developer)
                    .font(.subheadline)

                Divider()

                Text(L10n.Settings.apiNotice)
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider()

                Link(destination: URL(string: AppSettings.termsOfServiceURL)!) {
                    HStack {
                        Text(L10n.Settings.terms)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }

                Link(destination: URL(string: AppSettings.privacyPolicyURL)!) {
                    HStack {
                        Text(L10n.Settings.privacy)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
        } label: {
            Label(L10n.Settings.legal, systemImage: "doc.text")
                .font(.headline)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: shareApp) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(L10n.Settings.shareApp)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button(action: rateApp) {
                HStack {
                    Image(systemName: "star.fill")
                    Text(L10n.Settings.rateApp)
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

    private var currentQualityDisplay: String {
        guard let quality = AppSettings.StreamQuality(rawValue: streamQuality) else {
            return AppSettings.StreamQuality.high.localizedName
        }
        return quality.localizedName
    }

    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            appearAnimation = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }

    private func shareApp() {
        let shareText = L10n.Settings.shareMessage
        let shareURL = URL(string: AppSettings.appStoreURL)

        var items: [Any] = [shareText]
        if let url = shareURL {
            items.append(url)
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .saveToCameraRoll
        ]

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func rateApp() {
        if let url = URL(string: AppSettings.appReviewURL) {
            UIApplication.shared.open(url)
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
