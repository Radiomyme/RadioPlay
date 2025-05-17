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
            // Fond
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Fond avec effet de flou
            if let artwork = viewModel.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 40)
                    .opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Contenu principal
            VStack(spacing: 30) {
                // Station info
                Text(station.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                Spacer()
                
                // Artwork
                ArtworkView(artwork: viewModel.artwork, isBuffering: viewModel.isBuffering)

                Spacer()
                
                // Track info
                VStack(spacing: 8) {
                    Text(viewModel.currentTrack?.title ?? "En direct")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(viewModel.currentTrack?.artist ?? station.subtitle)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .padding(.horizontal)

                if viewModel.isPlaying && !viewModel.isBuffering {
                    AudioVisualizerView(isPlaying: viewModel.isPlaying)
                        .padding(.top, 10)
                }

                Spacer()
                
                // Controls
                HStack(spacing: 40) {
                    Button(action: {
                        viewModel.shareTrack()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        viewModel.openInAppleMusic()
                    }) {
                        Image(systemName: "music.note")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 30)

                Button(action: {
                    isSleepTimerPresented = true
                }) {
                    Image(systemName: viewModel.sleepTimerService.isActive ? "timer" : "timer")
                        .font(.title)
                        .foregroundColor(viewModel.sleepTimerService.isActive ? .blue : .white)
                        .overlay(
                            viewModel.sleepTimerService.isActive ?
                            Text(viewModel.sleepTimerService.formattedTimeRemaining())
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .offset(x: 12, y: 12) : nil
                        )
                }

                // AirPlay button
                AirPlayButton()
                    .frame(width: 30, height: 30)
                    .padding(.bottom)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackButton(dismiss: dismiss))
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

struct BackButton: View {
    let dismiss: DismissAction

    var body: some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Retour")
            }
            .foregroundColor(.white)
        }
    }
}
