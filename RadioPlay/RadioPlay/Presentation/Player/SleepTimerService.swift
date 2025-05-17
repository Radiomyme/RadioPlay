//
//  SleepTimerService.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Domain/Services/SleepTimerService.swift
import Foundation
import Combine

class SleepTimerService: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isActive = false
    
    private var timer: Timer?
    private var completionHandler: (() -> Void)?
    
    func startTimer(duration: TimeInterval, completion: @escaping () -> Void) {
        timeRemaining = duration
        isActive = true
        completionHandler = completion
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1.0
            } else {
                self.stopTimer()
                self.completionHandler?()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        timeRemaining = 0
        completionHandler = nil
    }
    
    func formattedTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        timer?.invalidate()
    }
}