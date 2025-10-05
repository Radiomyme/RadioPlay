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
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            if isBuffering {
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
            } else if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            scale = 1.0
                            opacity = 1.0
                        }
                    }
                    .onChange(of: artwork) { _ in
                        // Animation de transition
                        scale = 0.8
                        opacity = 0
                        rotation = -5

                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            scale = 1.0
                            opacity = 1.0
                            rotation = 0
                        }
                    }
            } else {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.3), Color.black]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 240, height: 240)
                        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)

                    Image(systemName: "music.note")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(60)
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.3)) {
                        opacity = 1.0
                    }
                }
            }
        }
        .frame(height: 300)
    }
}
