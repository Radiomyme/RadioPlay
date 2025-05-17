//
//  MainView.swift (suite)
//  RadioPlay
//  
//  Created by Martin Parmentier on 17/05/2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var stationsViewModel = StationsViewModel()
    @EnvironmentObject private var audioManager: AudioPlayerManager
    
    var body: some View {
        ZStack {
            StationsView()
                .environmentObject(stationsViewModel)
                .environmentObject(audioManager)
                // Ajouter du padding en bas lorsque le mini-player est actif
                .padding(.bottom, audioManager.currentStation != nil ? 70 : 0)
                .animation(.easeInOut, value: audioManager.currentStation != nil)
        }
    }
}

// Modifications pour PlayerView
struct PlayerView: View {
    let station: Station
    @EnvironmentObject private var audioManager: AudioPlayerManager
    @EnvironmentObject private var stationsViewModel: StationsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSleepTimerPresented = false
    
    // Drag gesture state
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
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
                        // Bouton de retour à gauche
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("Retour")
                                        .font(.system(size: 17, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(20)
                            }
                            .padding(.leading, -5)
                            
                            Spacer()
                        }
                        
                        // Titre centré
                        Text(station.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: geometry.size.width * 0.6)
                        
                        // Bouton favoris à droite
                        HStack {
                            Spacer()
                            Button(action: {
                                stationsViewModel.toggleFavorite(station: station)
                            }) {
                                Image(systemName: stationsViewModel.isFavorite(station: station) ? "heart.fill" : "heart")
                                    .font(.system(size: 18))
                                    .foregroundColor(stationsViewModel.isFavorite(station: station) ? .red : .white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 4)
                        }
                    }
                    .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 12)
                    .padding(.horizontal, 12)
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
                            Image(systemName: audioManager.sleepTimerService.isActive ? "timer.circle.fill" : "timer.circle")
                                .font(.system(size: 22))
                                .foregroundColor(audioManager.sleepTimerService.isActive ? .blue : .white)
                        }
                        
                        AirPlayButton()
                            .frame(width: 30, height: 30)
                        
                        Spacer()
                    }
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                }
                .padding(.horizontal)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: dragOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Démarrer la lecture
            audioManager.play(station: station)
        }
        .sheet(isPresented: $isSleepTimerPresented) {
            SleepTimerView(
                sleepTimerService: audioManager.sleepTimerService,
                isPresented: $isSleepTimerPresented,
                onSetTimer: { duration in
                    audioManager.setupSleepTimer(duration: duration)
                },
                onCancelTimer: {
                    audioManager.cancelSleepTimer()
                }
            )
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Limite le geste au balayage de gauche à droite
                    if gesture.translation.width > 0 {
                        isDragging = true
                        dragOffset = gesture.translation.width
                    }
                }
                .onEnded { gesture in
                    isDragging = false
                    // Si l'utilisateur a glissé plus de 100 points, on revient en arrière
                    if gesture.translation.width > 100 {
                        dismiss()
                    } else {
                        // Sinon, on revient à la position de départ
                        dragOffset = 0
                    }
                }
        )
        // Indicateur visuel de balayage
        .overlay(
            HStack {
                // Indicateur visuel uniquement visible pendant le glissement
                if isDragging {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .padding(25)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(.leading, 20)
                        .transition(.opacity)
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.2), value: isDragging)
        )
    }
    
    private func shareCurrentTrack() {
        guard let track = audioManager.currentTrack else { return }
        
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
        
        // Construire la requête de recherche pour Apple Music
        let query = "\(track.artist) \(track.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://music.apple.com/search?term=\(query)"
        
        guard let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url)
    }
}
