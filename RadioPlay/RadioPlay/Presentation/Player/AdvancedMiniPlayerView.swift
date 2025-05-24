//
//  AdvancedMiniPlayerView.swift - Version simplifiée et fonctionnelle
//  RadioPlay
//
//  Created by Martin Parmentier on 24/05/2025.
//

import SwiftUI

struct AdvancedMiniPlayerView: View {
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @State private var expandProgress: CGFloat = 0 // 0 = mini, 1 = expanded
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isSleepTimerPresented = false
    @State private var sleepTimerService = SleepTimerService()

    @Namespace private var namespace

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fond noir progressif
                if expandProgress > 0 {
                    Color.black
                        .opacity(expandProgress * 0.8)
                        .ignoresSafeArea()
                }

                // Fond artwork flou
                if expandProgress > 0.3 {
                    backgroundView
                        .opacity(expandProgress)
                        .ignoresSafeArea()
                }

                // Player principal
                VStack {
                    Spacer()

                    playerView(geometry: geometry)
                        .frame(height: playerHeight(geometry: geometry))
                        .background(playerBackground)
                        .cornerRadius(playerCornerRadius, corners: [.topLeft, .topRight])
                        .shadow(
                            color: Color.black.opacity(0.2 * (1 - expandProgress)),
                            radius: 15 * (1 - expandProgress),
                            x: 0,
                            y: -8 * (1 - expandProgress)
                        )
                        .offset(y: dragOffset)
                        .gesture(unifiedDragGesture)
                        .onTapGesture {
                            if expandProgress < 0.1 {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    expandProgress = 1.0
                                }
                            }
                        }
                }
            }
        }
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.85), value: expandProgress)
        .sheet(isPresented: $isSleepTimerPresented) {
            SleepTimerView(
                sleepTimerService: sleepTimerService,
                isPresented: $isSleepTimerPresented,
                onSetTimer: { duration in setupSleepTimer(duration: duration) },
                onCancelTimer: { cancelSleepTimer() }
            )
        }
    }

    // MARK: - Main Player View

    private func playerView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Barre de progression (mini uniquement)
            if expandProgress < 0.5 {
                progressBar
                    .opacity(1.0 - (expandProgress * 2.0))
            }

            // Indicateur de glissement (mode étendu)
            if expandProgress > 0.5 {
                VStack(spacing: 0) {
                    Spacer().frame(height: 15)

                    dragHandle
                        .opacity(expandProgress)

                    Spacer().frame(height: 15)
                }
            }

            // Header (mode étendu)
            if expandProgress > 0.5 {
                headerView
                    .opacity(expandProgress)
                    .padding(.bottom, 20)
            }

            // Contenu principal
            if expandProgress < 0.5 {
                // Mode mini
                miniPlayerContent
                    .opacity(1.0 - (expandProgress * 2.0))
            } else {
                // Mode étendu
                fullPlayerContent(geometry: geometry)
                    .opacity((expandProgress - 0.5) * 2.0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, expandProgress < 0.5 ? 16 : 0)
    }

    // MARK: - Mini Player Content

    private var miniPlayerContent: some View {
        HStack(spacing: 12) {
            // Artwork
            artworkView
                .matchedGeometryEffect(id: "artwork", in: namespace)

            // Infos
            VStack(alignment: .leading, spacing: 3) {
                Text(audioManager.currentTrack?.title ?? audioManager.currentStation?.name ?? "")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "title", in: namespace)

                Text(audioManager.currentTrack?.artist ?? audioManager.currentStation?.subtitle ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "subtitle", in: namespace)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Contrôles
            HStack(spacing: 20) {
                Button(action: { audioManager.togglePlayPause() }) {
                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .matchedGeometryEffect(id: "playButton", in: namespace)

                Button(action: { audioManager.stop() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Full Player Content

    private func fullPlayerContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Artwork centré
            VStack {
                artworkView
                    .matchedGeometryEffect(id: "artwork", in: namespace)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // Infos piste
            VStack(spacing: 10) {
                if audioManager.isPlaying && !audioManager.isBuffering {
                    AudioVisualizerView(isPlaying: audioManager.isPlaying)
                        .frame(height: 22)
                        .padding(.bottom, 8)
                }

                Text(audioManager.currentTrack?.title ?? "En direct")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .matchedGeometryEffect(id: "title", in: namespace)

                Text(audioManager.currentTrack?.artist ?? audioManager.currentStation?.subtitle ?? "")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .matchedGeometryEffect(id: "subtitle", in: namespace)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 30)

            Spacer()

            // Contrôles principaux
            HStack(spacing: 55) {
                Button(action: shareCurrentTrack) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }

                Button(action: { audioManager.togglePlayPause() }) {
                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .frame(width: 75, height: 75)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .matchedGeometryEffect(id: "playButton", in: namespace)

                Button(action: openInAppleMusic) {
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 25)

            // Contrôles additionnels
            HStack(spacing: 75) {
                Button(action: { isSleepTimerPresented = true }) {
                    Image(systemName: sleepTimerService.isActive ? "timer.circle.fill" : "timer.circle")
                        .font(.system(size: 24))
                        .foregroundColor(sleepTimerService.isActive ? .blue : .white.opacity(0.7))
                }

                AirPlayButton()
                    .frame(width: 24, height: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 35)
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        ZStack {
            // Bouton gauche
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        expandProgress = 0
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                }
                Spacer()
            }

            // Titre centré
            Text(audioManager.currentStation?.name ?? "")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)

            // Bouton droite
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        expandProgress = 0
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Components

    private var backgroundView: some View {
        ZStack {
            if let artwork = audioManager.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 50)
                    .opacity(0.4)
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.white.opacity(0.4))
            .frame(width: 36, height: 5)
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 2)

            if audioManager.isPlaying && !audioManager.isBuffering {
                HStack(spacing: 1) {
                    ForEach(0..<12, id: \.self) { index in
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 2)
                            .scaleEffect(y: CGFloat.random(in: 0.3...1.0), anchor: .bottom)
                            .animation(
                                .easeInOut(duration: 0.15)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.04),
                                value: audioManager.isPlaying
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var artworkView: some View {
        ZStack {
            let size: CGFloat = expandProgress < 0.5 ? 50 : 240
            let cornerRadius: CGFloat = expandProgress < 0.5 ? 8 : 18

            Group {
                if let artwork = audioManager.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    AsyncImage(url: URL(string: audioManager.currentStation?.logoURL ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.gray.opacity(0.2))
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "radio")
                                        .font(.system(size: size * 0.25))
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: .black.opacity(expandProgress > 0.5 ? 0.4 : 0),
                radius: expandProgress > 0.5 ? 20 : 0,
                x: 0,
                y: expandProgress > 0.5 ? 12 : 0
            )

            if audioManager.isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(expandProgress < 0.5 ? 0.8 : 1.2)
                    .frame(width: size, height: size)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }

    // MARK: - Computed Properties

    private func playerHeight(geometry: GeometryProxy) -> CGFloat {
        let minHeight: CGFloat = 70
        let maxHeight = geometry.size.height - 90
        return minHeight + (maxHeight - minHeight) * expandProgress
    }

    private var playerCornerRadius: CGFloat {
        12 * (1 - expandProgress)
    }

    private var playerBackground: Color {
        if expandProgress > 0.3 {
            return Color.clear
        } else {
            return Color(red: 0.11, green: 0.11, blue: 0.11)
        }
    }

    // MARK: - Unified Drag Gesture

    private var unifiedDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                let translation = value.translation.height

                if expandProgress < 0.5 {
                    // Mode mini - glissement vers le haut
                    if translation < 0 {
                        dragOffset = translation * 0.8
                        let progress = min(1.0, abs(translation) / 120)
                        expandProgress = progress
                    }
                } else {
                    // Mode étendu - glissement vers le bas
                    if translation > 0 {
                        dragOffset = translation * 0.8
                        let progress = max(0.0, 1.0 - (translation / 150))
                        expandProgress = progress
                    }
                }
            }
            .onEnded { value in
                isDragging = false
                let velocity = value.translation.height

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    if expandProgress < 0.5 {
                        if velocity < -40 || expandProgress > 0.3 {
                            expandProgress = 1.0
                        } else {
                            expandProgress = 0.0
                        }
                    } else {
                        if velocity > 50 || expandProgress < 0.7 {
                            expandProgress = 0.0
                        } else {
                            expandProgress = 1.0
                        }
                    }
                    dragOffset = 0
                }
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

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
