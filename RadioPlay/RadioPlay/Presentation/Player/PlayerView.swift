//
//  PlayerView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Player/PlayerView.swift
import SwiftUI
import AVKit

struct PlayerView: View {
    let station: Station
    @StateObject private var viewModel: PlayerViewModel
    @State private var isSleepTimerPresented = false
    @Environment(\.dismiss) private var dismiss

    init(station: Station) {
        self.station = station
        _viewModel = StateObject(wrappedValue: PlayerViewModel(station: station))
    }

    var body: some View {
        ZStack {
            // Fond avec flou de l'image
            Color.black.edgesIgnoringSafeArea(.all)

            if let artwork = viewModel.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 40)
                    .opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
            }

            // Overlay pour assombrir légèrement
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.4), Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // Interface principale
            VStack(spacing: 0) {
                // En-tête avec nom de la station
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Retour")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()

                    Text(station.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Bouton pour les favoris
                    Button(action: {
                        // Action pour ajouter aux favoris
                    }) {
                        Image(systemName: "heart")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)

                Spacer()

                // Artwork au centre
                ArtworkView(artwork: viewModel.artwork, isBuffering: viewModel.isBuffering)

                Spacer()

                // Informations sur la piste
                VStack(spacing: 12) {
                    // Visualisateur audio uniquement si en lecture
                    if viewModel.isPlaying && !viewModel.isBuffering {
                        AudioVisualizerView(isPlaying: viewModel.isPlaying)
                            .frame(height: 30)
                            .padding(.bottom, 10)
                    }

                    Text(viewModel.currentTrack?.title ?? "En direct")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 30)

                    Text(viewModel.currentTrack?.artist ?? station.subtitle)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)

                Spacer()

                // Contrôles
                HStack(spacing: 24) {
                    Spacer()

                    Button(action: {
                        viewModel.shareTrack()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.2))
                                .frame(width: 50, height: 50)

                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }

                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 70, height: 70)
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)

                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }

                    Button(action: {
                        viewModel.openInAppleMusic()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.2))
                                .frame(width: 50, height: 50)

                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, 30)

                // Barre du bas avec éléments supplémentaires
                HStack(spacing: 30) {
                    Spacer()

                    Button(action: {
                        isSleepTimerPresented = true
                    }) {
                        Image(systemName: viewModel.sleepTimerService.isActive ? "timer.circle.fill" : "timer.circle")
                            .font(.system(size: 22))
                            .foregroundColor(viewModel.sleepTimerService.isActive ? .blue : .white)
                    }

                    AirPlayButton()
                        .frame(width: 30, height: 30)

                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.startPlaying()
        }
        .onDisappear {
            viewModel.stopPlaying()
        }
        .sheet(isPresented: $isSleepTimerPresented) {
            SleepTimerView(
                sleepTimerService: viewModel.sleepTimerService,
                isPresented: $isSleepTimerPresented,
                onSetTimer: { duration in
                    viewModel.setupSleepTimer(duration: duration)
                },
                onCancelTimer: {
                    viewModel.cancelSleepTimer()
                }
            )
        }
    }
}
