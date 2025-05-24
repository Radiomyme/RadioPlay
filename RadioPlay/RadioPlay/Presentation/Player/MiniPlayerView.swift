//
//  SimpleMiniPlayerView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 24/05/2025.
//

import SwiftUI

struct SimpleMiniPlayerView: View {
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @State private var isPlayerExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Barre de progression
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 2)

                if audioManager.isPlaying && !audioManager.isBuffering {
                    HStack(spacing: 1) {
                        ForEach(0..<10, id: \.self) { index in
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .scaleEffect(y: CGFloat.random(in: 0.3...1.0), anchor: .bottom)
                                .animation(
                                    Animation
                                        .easeInOut(duration: 0.2)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.05),
                                    value: audioManager.isPlaying
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Contenu du mini player
            HStack(spacing: 12) {
                // Artwork
                ZStack {
                    if let artwork = audioManager.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .cornerRadius(6)
                    } else {
                        AsyncImage(url: URL(string: audioManager.currentStation?.logoURL ?? "")) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.2))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.2))
                                    .overlay(
                                        Image(systemName: "radio")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 48, height: 48)
                        .cornerRadius(6)
                    }

                    if audioManager.isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .frame(width: 48, height: 48)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(6)
                    }
                }

                // Infos
                VStack(alignment: .leading, spacing: 2) {
                    Text(audioManager.currentTrack?.title ?? audioManager.currentStation?.name ?? "")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(audioManager.currentTrack?.artist ?? audioManager.currentStation?.subtitle ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Contrôles
                HStack(spacing: 16) {
                    Button(action: {
                        audioManager.togglePlayPause()
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        audioManager.stop()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.12))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -5)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .onTapGesture {
                isPlayerExpanded = true
            }
        }
        .frame(height: 70) // Hauteur fixe
        .fullScreenCover(isPresented: $isPlayerExpanded) {
            if let station = audioManager.currentStation {
                FullPlayerView(station: station, isPresented: $isPlayerExpanded)
                    .environmentObject(audioManager)
            }
        }
    }
}

// Version simplifiée du lecteur complet
struct FullPlayerView: View {
    let station: Station
    @Binding var isPresented: Bool
    @EnvironmentObject private var audioManager: AudioPlayerManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                if let artwork = audioManager.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .blur(radius: 40)
                        .opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                }

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Text(station.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        // Placeholder pour équilibrer
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer()

                    // Artwork
                    ZStack {
                        if let artwork = audioManager.artwork {
                            Image(uiImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 280, height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(white: 0.2))
                                .frame(width: 280, height: 280)
                                .overlay(
                                    Image(systemName: "radio")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                )
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
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(20)
                        }
                    }

                    Spacer()

                    // Track info
                    VStack(spacing: 16) {
                        if audioManager.isPlaying && !audioManager.isBuffering {
                            AudioVisualizerView(isPlaying: audioManager.isPlaying)
                                .frame(height: 30)
                        }

                        Text(audioManager.currentTrack?.title ?? "En direct")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 30)

                        Text(audioManager.currentTrack?.artist ?? station.subtitle)
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 30)
                    }

                    Spacer()

                    // Controls
                    HStack(spacing: 40) {
                        Button(action: {
                            // Share
                        }) {
                            Circle()
                                .fill(Color(white: 0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )
                        }

                        Button(action: {
                            audioManager.togglePlayPause()
                        }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                        }

                        Button(action: {
                            // Apple Music
                        }) {
                            Circle()
                                .fill(Color(white: 0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
}
