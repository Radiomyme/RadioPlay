//
//  ArtworkView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Player/ArtworkView.swift
import SwiftUI

struct ArtworkView: View {
    let artwork: UIImage?
    let isBuffering: Bool
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            if isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(width: 250, height: 250)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
            } else if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            scale = 1.0
                            opacity = 1.0
                        }
                    }
                    .onChange(of: artwork) { _ in
                        scale = 0.8
                        opacity = 0
                        
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            scale = 1.0
                            opacity = 1.0
                        }
                    }
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(40)
                    .frame(width: 250, height: 250)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(20)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.3)) {
                            opacity = 1.0
                        }
                    }
            }
        }
        .frame(height: 270)
    }
}