import SwiftUI

struct SleepTimerView: View {
    @ObservedObject var sleepTimerService: SleepTimerService
    @Binding var isPresented: Bool

    let onSetTimer: (TimeInterval) -> Void
    let onCancelTimer: () -> Void

    private let timerOptions: [TimeInterval] = [
        5 * 60,
        15 * 60,
        30 * 60,
        45 * 60,
        60 * 60,
        90 * 60
    ]

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient

                VStack(spacing: 20) {
                    if sleepTimerService.isActive {
                        activeTimerView
                    } else {
                        timerOptionsView
                    }
                }
            }
            .navigationTitle(L10n.SleepTimer.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.General.close) {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.1, green: 0.1, blue: 0.2)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: - Active Timer

    private var activeTimerView: some View {
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

                    Text(L10n.SleepTimer.remaining)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Button(action: {
                onCancelTimer()
            }) {
                Text(L10n.SleepTimer.cancel)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(Color.red)
                    .cornerRadius(25)
                    .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 5)
            }
        }
    }

    // MARK: - Timer Options

    private var timerOptionsView: some View {
        VStack(spacing: 20) {
            Text(L10n.SleepTimer.selectDuration)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(timerOptions, id: \.self) { option in
                    timerOptionButton(duration: option)
                }
            }
            .padding(.horizontal)
        }
    }

    private func timerOptionButton(duration: TimeInterval) -> some View {
        Button(action: {
            onSetTimer(duration)
            isPresented = false
        }) {
            VStack {
                Text(formatDuration(duration))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text(formatDurationLabel(duration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(white: 0.15))
            .cornerRadius(15)
        }
    }

    // MARK: - Formatting Helpers

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

    private func formatDurationLabel(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes == 60 {
            return L10n.SleepTimer.hour
        } else if minutes < 60 {
            return L10n.SleepTimer.minutes(minutes)
        } else {
            let hours = minutes / 60
            return L10n.SleepTimer.hours(hours)
        }
    }
}
