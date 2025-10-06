import SwiftUI
import Combine

struct NowPlayingBarTV: View {
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @FocusState private var playButtonFocused: Bool
    @FocusState private var stopButtonFocused: Bool

    var body: some View {
        HStack(spacing: 40) {
            // Artwork & Info
            HStack(spacing: 32) {
                // Artwork
                ZStack {
                    if let artwork = audioManager.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if let logoURL = audioManager.currentStation?.logoURL {
                        AsyncImage(url: URL(string: logoURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "radio")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if audioManager.isBuffering {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 140, height: 140)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.5)
                            )
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                // Track Info
                VStack(alignment: .leading, spacing: 8) {
                    if let track = audioManager.currentTrack, !track.title.isEmpty {
                        Text(track.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(track.artist)
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text(audioManager.currentStation?.name ?? "")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(audioManager.currentStation?.subtitle ?? "")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    // Status
                    HStack(spacing: 12) {
                        if audioManager.isPlaying && !audioManager.isBuffering {
                            AnimatedWaveformTV()
                                .frame(width: 60, height: 24)
                        }

                        Circle()
                            .fill(audioManager.isPlaying ? Color.green : Color.red)
                            .frame(width: 12, height: 12)

                        Text(audioManager.isPlaying ? "En écoute" : "En pause")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // Controls
            HStack(spacing: 32) {
                // Play/Pause
                Button(action: { audioManager.togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(playButtonFocused ? 1.15 : 1.0)
                    .shadow(
                        color: playButtonFocused ? Color.blue.opacity(0.6) : Color.clear,
                        radius: 20,
                        x: 0,
                        y: 10
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: playButtonFocused)
                }
                .buttonStyle(.plain)
                .focused($playButtonFocused)

                // Stop
                Button(action: { audioManager.stop() }) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "stop.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                    }
                    .scaleEffect(stopButtonFocused ? 1.15 : 1.0)
                    .shadow(
                        color: stopButtonFocused ? Color.red.opacity(0.6) : Color.clear,
                        radius: 20,
                        x: 0,
                        y: 10
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: stopButtonFocused)
                }
                .buttonStyle(.plain)
                .focused($stopButtonFocused)
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 40)
        .background(nowPlayingBackground)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var nowPlayingBackground: some View {
        ZStack {
            // Blur effect (tvOS compatible)
            VisualEffectBlur(blurStyle: .dark)

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Top border
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.5),
                                Color.blue.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                Spacer()
            }
        }
    }
}

// MARK: - Animated Waveform

struct AnimatedWaveformTV: View {
    @State private var heights: [CGFloat] = [0.3, 0.6, 0.9, 0.5, 0.7]

    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 6, height: 24 * heights[index])
                    .animation(.easeInOut(duration: 0.3), value: heights[index])
            }
        }
        .frame(height: 24)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                heights = heights.map { _ in CGFloat.random(in: 0.3...1.0) }
            }
        }
    }
}

// MARK: - Visual Effect Blur

struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
