//
//  LaunchScreenView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 03/10/2025.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Couleur de fond sombre pour matcher votre thème
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo ou icône de l'app (si vous en avez un)
                Image(systemName: "radio.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                // Nom de l'app
                Text("RadioPlay")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Optionnel : indicateur de chargement
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}