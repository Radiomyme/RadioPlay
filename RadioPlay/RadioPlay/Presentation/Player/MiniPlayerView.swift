//
//  MiniPlayerView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @State private var isPlayerExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Barre de progression/visualisateur
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
                } else if audioManager.isBuffering {
                    // Indicateur de buffering
                    Rectangle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 30, height: 2)
                        .offset(x: -30)
                        .animation(
                            Animation
                                .linear(duration: 1.0)
                                .repeatForever(autoreverses: false),
                            value: audioManager.isBuffering
                        )
                }
            }
            
            // Contenu principal du mini player
            HStack(spacing: 12) {
                // Image de la station ou artwork
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
                    
                    // Indicateur de buffering au centre de l'image
                    if audioManager.isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .frame(width: 48, height: 48)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(6)
                    }
                }
                
                // Informations sur la station/piste
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
                
                // Boutons de contrôle
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
            .sheet(isPresented: $isPlayerExpanded) {
                if let station = audioManager.currentStation {
                    FullPlayerView(station: station, isPresented: $isPlayerExpanded)
                        .environmentObject(audioManager)
                }
            }
        }
    }
}

// Version complète du lecteur pour la modal
struct FullPlayerView: View {
    let station: Station
    @Binding var isPresented: Bool
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @State private var isSleepTimerPresented = false
    @State private var sleepTimerService = SleepTimerService()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fond avec flou de l'image
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
                    ZStack {
                        // Bouton de fermeture à gauche
                        HStack {
                            Button(action: { isPresented = false }) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .padding(.leading, 4)
                            
                            Spacer()
                        }
                        
                        // Titre centré
                        Text(station.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: geometry.size.width * 0.6)
                    }
                    .padding(.top, geometry.safeAreaInsets.top > 0 ? 10 : 20)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Artwork au centre
                    ArtworkView(artwork: audioManager.artwork, isBuffering: audioManager.isBuffering)
                        .frame(width: min(geometry.size.width * 0.9, 350))
                    
                    Spacer()
                    
                    // Informations sur la piste
                    VStack(spacing: 16) {
                        // Visualisateur audio uniquement si en lecture
                        if audioManager.isPlaying && !audioManager.isBuffering {
                            AudioVisualizerView(isPlaying: audioManager.isPlaying)
                                .frame(height: 30)
                                .padding(.bottom, 10)
                        }
                        
                        Text(audioManager.currentTrack?.title ?? "En direct")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 30)
                        
                        Text(audioManager.currentTrack?.artist ?? station.subtitle)
                            .font(.system(size: 20))
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
                            // Partager
                            shareCurrentTrack()
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
                            audioManager.togglePlayPause()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 70, height: 70)
                                    .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Button(action: {
                            openInAppleMusic()
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
                            Image(systemName: sleepTimerService.isActive ? "timer.circle.fill" : "timer.circle")
                                .font(.system(size: 22))
                                .foregroundColor(sleepTimerService.isActive ? .blue : .white)
                        }
                        
                        AirPlayButton()
                            .frame(width: 30, height: 30)
                        
                        Spacer()
                    }
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                }
                .padding(.horizontal)
            }
            .edgesIgnoringSafeArea(.all)
            .sheet(isPresented: $isSleepTimerPresented) {
                SleepTimerView(
                    sleepTimerService: sleepTimerService,
                    isPresented: $isSleepTimerPresented,
                    onSetTimer: { duration in
                        setupSleepTimer(duration: duration)
                    },
                    onCancelTimer: {
                        cancelSleepTimer()
                    }
                )
            }
        }
    }
    
    private func shareCurrentTrack() {
        guard let track = audioManager.currentTrack else { return }
        
        let text = "J'écoute \(track.title) par \(track.artist) sur \(station.name) via Radio Play!"
        
        var items: [Any] = [text]
        
        if let artwork = audioManager.artwork {
            items.append(artwork)
        }
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Utiliser AppUtility
        if let rootVC = AppUtility.rootViewController {
            rootVC.present(activityViewController, animated: true)
        }
    }
    
    private func openInAppleMusic() {
        guard let track = audioManager.currentTrack else { return }
        
        // Construire la requête de recherche pour Apple Music
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
