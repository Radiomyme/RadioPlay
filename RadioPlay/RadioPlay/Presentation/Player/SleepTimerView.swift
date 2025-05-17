//
//  SleepTimerView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Player/SleepTimerView.swift
import SwiftUI

struct SleepTimerView: View {
    @ObservedObject var sleepTimerService: SleepTimerService
    @Binding var isPresented: Bool
    
    let onSetTimer: (TimeInterval) -> Void
    let onCancelTimer: () -> Void
    
    private let timerOptions: [TimeInterval] = [
        5 * 60,    // 5 minutes
        15 * 60,   // 15 minutes
        30 * 60,   // 30 minutes
        45 * 60,   // 45 minutes
        60 * 60,   // 1 heure
        90 * 60    // 1 heure 30
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if sleepTimerService.isActive {
                        VStack(spacing: 20) {
                            Text("Minuterie active")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(sleepTimerService.formattedTimeRemaining())
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                onCancelTimer()
                            }) {
                                Text("Annuler la minuterie")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        }
                    } else {
                        List {
                            ForEach(timerOptions, id: \.self) { option in
                                Button(action: {
                                    onSetTimer(option)
                                    isPresented = false
                                }) {
                                    Text(formatDuration(option))
                                        .foregroundColor(.white)
                                }
                                .listRowBackground(Color.black)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Minuterie de veille")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) heure\(hours > 1 ? "s" : "")"
            } else {
                return "\(hours) heure\(hours > 1 ? "s" : "") \(remainingMinutes) min"
            }
        }
    }
}