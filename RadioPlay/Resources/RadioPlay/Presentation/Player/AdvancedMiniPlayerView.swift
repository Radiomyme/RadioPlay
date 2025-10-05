//
//  AdvancedMiniPlayerView.swift - Version finale avec Liquid Glass
//  RadioPlay
//
//  Created by Martin Parmentier.
//

import SwiftUI

struct AdvancedMiniPlayerView: View {
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @State private var isSleepTimerPresented = false
    @State private var sleepTimerService = SleepTimerService()

    @Namespace private var animationNamespace

    // Constantes pour le layout
    private let miniPlayerHeight: CGFloat = 64
    private let miniPlayerBottomPadding: CGFloat = 12

    var body: some View {
        ZStack(alignment: .bottom) {
            // Overlay noir pour le mode étendu
            if isExpanded {
                Color.black
                    .opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }
            }

            // Container principal
            if isExpanded {
                // Vue étendue
                expandedPlayerView()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            } else {
                // Mini player avec safe area
                miniPlayerView()
                    .padding(.bottom, safeAreaBottom)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isExpanded)
        .sheet(isPresented: $isSleepTimerPresented) {
            SleepTimerView(
                sleepTimerService: sleepTimerService,
                isPresented: $isSleepTimerPresented,
                onSetTimer: { duration in setupSleepTimer(duration: duration) },
                onCancelTimer: { cancelSleepTimer() }
            )
        }
    }

    // ✅ Calcul de la safe area bottom
    private var safeAreaBottom: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        return keyWindow?.safeAreaInsets.bottom ?? 0
    }

    // MARK: - Mini Player View

    private func miniPlayerView() -> some View {
        HStack(spacing: 12) {
            // Artwork avec animation - affiche le logo de la station si pas d'artwork
            ZStack {
                if let artwork = audioManager.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .matchedGeometryEffect(id: "artwork", in: animationNamespace)
                } else if let logoURL = audioManager.currentStation?.logoURL, !logoURL.isEmpty {
                    // ✅ Afficher le logo de la station si pas d'artwork de piste
                    AsyncImage(url: URL(string: logoURL)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                        .scaleEffect(0.6)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "radio")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .matchedGeometryEffect(id: "artwork", in: animationNamespace)
                } else {
                    // Placeholder par défaut
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "radio")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                        .matchedGeometryEffect(id: "artwork", in: animationNamespace)
                }

                if audioManager.isBuffering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .blue))
                        .scaleEffect(0.8)
                        .frame(width: 56, height: 56)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Infos avec animation - affiche les infos de la station si pas de piste
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(miniPlayerTextColor)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "title", in: animationNamespace)

                Text(displaySubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "subtitle", in: animationNamespace)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Visualiseur audio animé
            if audioManager.isPlaying && !audioManager.isBuffering {
                AnimatedAudioBarsView()
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 12)
            }

            // Contrôles
            Button(action: { audioManager.togglePlayPause() }) {
                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(miniPlayerAccentColor)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .matchedGeometryEffect(id: "playButton", in: animationNamespace)
            }

            Button(action: { audioManager.stop() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 80)
        .background(miniPlayerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.2), radius: 20, x: 0, y: -5)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isExpanded = true
            }
        }
    }

    // ✅ NOUVEAU - Propriétés calculées pour affichage intelligent
    private var displayTitle: String {
        if let track = audioManager.currentTrack, !track.title.isEmpty {
            return track.title
        }
        return audioManager.currentStation?.name ?? "Radio"
    }

    private var displaySubtitle: String {
        if let track = audioManager.currentTrack, !track.artist.isEmpty {
            return track.artist
        }
        return audioManager.currentStation?.subtitle ?? "En direct"
    }

    // ✅ Effet Liquid Glass pour player flottant
    @ViewBuilder
    private var miniPlayerBackground: some View {
        if colorScheme == .dark {
            // Mode sombre - effet glass sombre
            ZStack {
                // Fond avec blur
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Overlay avec gradient subtil
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Bordure lumineuse
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        } else {
            // Mode clair - effet glass lumineux
            ZStack {
                // Fond avec blur
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Overlay avec gradient clair
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Bordure subtile
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.gray.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
    }

    // ✅ Couleurs adaptatives pour le mini-player
    private var miniPlayerTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var miniPlayerAccentColor: Color {
        colorScheme == .dark ? .white : .blue
    }

    // MARK: - Expanded Player View

    private func expandedPlayerView() -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag Handle
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                    Spacer()
                }

                // Header
                expandedHeader()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                // Contenu centré verticalement
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    // Artwork avec animation - Logo de la station si pas d'artwork
                    ZStack {
                        if let artwork = audioManager.artwork {
                            Image(uiImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 280, height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
                                .matchedGeometryEffect(id: "artwork", in: animationNamespace)
                        } else if let logoURL = audioManager.currentStation?.logoURL, !logoURL.isEmpty {
                            AsyncImage(url: URL(string: logoURL)) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 280, height: 280)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 280, height: 280)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
                                case .failure:
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 280, height: 280)
                                        .overlay(
                                            Image(systemName: "radio")
                                                .font(.system(size: 70))
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .matchedGeometryEffect(id: "artwork", in: animationNamespace)
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 280, height: 280)
                                .overlay(
                                    Image(systemName: "radio")
                                        .font(.system(size: 70))
                                        .foregroundColor(.gray)
                                )
                                .matchedGeometryEffect(id: "artwork", in: animationNamespace)
                        }

                        if audioManager.isBuffering {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)

                                Text("Chargement...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 10)
                            }
                            .frame(width: 280, height: 280)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.bottom, 50)

                    // Infos piste avec animation - Infos de la station si pas de piste
                    VStack(spacing: 12) {
                        if audioManager.isPlaying && !audioManager.isBuffering {
                            AudioVisualizerView(isPlaying: audioManager.isPlaying)
                                .frame(height: 24)
                                .padding(.horizontal, 60)
                                .padding(.bottom, 8)
                        }

                        Text(displayTitle)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 40)
                            .matchedGeometryEffect(id: "title", in: animationNamespace)

                        Text(displaySubtitle)
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 40)
                            .matchedGeometryEffect(id: "subtitle", in: animationNamespace)
                    }
                    .padding(.bottom, 60)

                    // Contrôles principaux
                    HStack(spacing: 60) {
                        controlButton(
                            icon: "square.and.arrow.up",
                            size: 22,
                            action: shareCurrentTrack
                        )

                        // Bouton play/pause principal avec animation
                        Button(action: { audioManager.togglePlayPause() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)

                                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.black)
                                    .matchedGeometryEffect(id: "playButton", in: animationNamespace)
                            }
                            .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 5)
                        }

                        controlButton(
                            icon: "music.note",
                            size: 22,
                            action: openInAppleMusic
                        )
                    }
                    .padding(.bottom, 40)

                    // Contrôles secondaires
                    HStack(spacing: 80) {
                        Button(action: { isSleepTimerPresented = true }) {
                            Image(systemName: sleepTimerService.isActive ? "timer.circle.fill" : "timer.circle")
                                .font(.system(size: 26))
                                .foregroundColor(sleepTimerService.isActive ? .blue : .white.opacity(0.7))
                        }

                        AirPlayButton()
                            .frame(width: 26, height: 26)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(expandedPlayerBackground(geometry: geometry))
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height * 0.5
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 || value.velocity.height > 800 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded = false
                            }
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }

    // ✅ Fond du player étendu avec logo de la station en arrière-plan
    @ViewBuilder
    private func expandedPlayerBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            // Fond avec artwork/logo flou
            if let artwork = audioManager.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: 60)
                    .opacity(0.3)
            } else if let logoURL = audioManager.currentStation?.logoURL, !logoURL.isEmpty {
                // Utiliser le logo de la station en arrière-plan
                AsyncImage(url: URL(string: logoURL)) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .blur(radius: 80)
                            .opacity(0.2)
                    }
                }
            }

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Components

    private func expandedHeader() -> some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded = false
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            Spacer()

            Text(audioManager.currentStation?.name ?? "")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            // Espace pour équilibrer
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private func controlButton(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }

    // MARK: - Helper Functions

    private func shareCurrentTrack() {
        guard let track = audioManager.currentTrack,
              let station = audioManager.currentStation else { return }

        let text = "J'écoute \(track.title) par \(track.artist) sur \(station.name) via Radio Play!"
        var items: [Any] = [text]

        if let artwork = audioManager.artwork {
            items.append(artwork)
        }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let rootVC = AppUtility.rootViewController {
            rootVC.present(activityViewController, animated: true)
        }
    }

    private func openInAppleMusic() {
        guard let track = audioManager.currentTrack else { return }

        let query = "\(track.artist) \(track.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://music.apple.com/search?term=\(query)"

        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func setupSleepTimer(duration: TimeInterval) {
        sleepTimerService.startTimer(duration: duration) { [weak audioManager] in
            audioManager?.stop()
        }
    }

    private func cancelSleepTimer() {
        sleepTimerService.stopTimer()
    }
}

// MARK: - Composant de visualiseur audio animé

struct AnimatedAudioBarsView: View {
    @State private var heights: [CGFloat] = [0.3, 0.6, 0.9, 0.5]

    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white)
                    .frame(width: 3, height: 24 * heights[index])
                    .animation(.easeInOut(duration: 0.3), value: heights[index])
            }
        }
        .frame(height: 24)
        .onReceive(timer) { _ in
            // Générer de nouvelles hauteurs aléatoires pour créer l'animation
            withAnimation(.easeInOut(duration: 0.3)) {
                heights = heights.map { _ in CGFloat.random(in: 0.2...1.0) }
            }
        }
    }
}
