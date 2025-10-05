//
//  AirPlayButton.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Player/AirPlayButton.swift
import SwiftUI
import AVKit

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = .white
        
        // Créer un conteneur pour ajuster la taille
        let container = UIView()
        container.addSubview(routePickerView)
        
        routePickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            routePickerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            routePickerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            routePickerView.topAnchor.constraint(equalTo: container.topAnchor),
            routePickerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Rien à mettre à jour
    }
}