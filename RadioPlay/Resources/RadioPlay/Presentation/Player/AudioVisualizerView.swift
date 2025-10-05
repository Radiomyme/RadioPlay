//
//  AudioVisualizerView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Player/AudioVisualizerView.swift
import SwiftUI

struct AudioVisualizerView: View {
    let isPlaying: Bool
    
    @State private var levels: [CGFloat] = [0.2, 0.5, 0.3, 0.8, 0.4, 0.7, 0.3, 0.5]
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<levels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4, height: 20 * levels[index])
                    .animation(.linear(duration: 0.2), value: levels[index])
            }
        }
        .frame(height: 20)
        .padding(.horizontal)
        .onAppear {
            if isPlaying {
                startVisualization()
            }
        }
        .onDisappear {
            stopVisualization()
        }
        .onChange(of: isPlaying) { newValue in
            if newValue {
                startVisualization()
            } else {
                stopVisualization()
            }
        }
    }
    
    private func startVisualization() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            levels = levels.map { _ in CGFloat.random(in: 0.1...1.0) }
        }
    }
    
    private func stopVisualization() {
        timer?.invalidate()
        timer = nil
        levels = levels.map { _ in 0.1 }
    }
}