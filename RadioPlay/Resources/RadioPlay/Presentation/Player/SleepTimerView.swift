//
//  SleepTimerView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


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
                // Fond avec dégradé
                LinearGradient(gradient:
                    Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    if sleepTimerService.isActive {
                        // Affichage du minuteur actif
                        VStack(spacing: 25) {
                            ZStack {
                                Circle()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 15)
                                    .frame(width: 200, height: 200)

                                Circle()
                                    .trim(from: 0, to: CGFloat(sleepTimerService.timeRemaining / sleepTimerService.initialDuration))
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                    .frame(width: 200, height: 200)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear, value: sleepTimerService.timeRemaining)

                                VStack {
                                    Text(sleepTimerService.formattedTimeRemaining())
                                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)

                                    Text("Restant")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }

                            Button(action: {
                                onCancelTimer()
                            }) {
                                Text("Annuler la minuterie")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 30)
                                    .background(Color.red)
                                    .cornerRadius(25)
                                    .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                        }
                    } else {
                        // Options de minuterie
                        Text("Sélectionner une durée")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(timerOptions, id: \.self) { option in
                                Button(action: {
                                    onSetTimer(option)
                                    isPresented = false
                                }) {
                                    VStack {
                                        Text(formatDuration(option))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)

                                        Text(option == 60 * 60 ? "1 heure" : "\(Int(option / 60)) min")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color(white: 0.15))
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Minuterie de veille")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)min"
            }
        }
    }
}
