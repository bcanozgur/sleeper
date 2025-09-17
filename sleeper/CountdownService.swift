//
//  CountdownService.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import Foundation
import Combine

class CountdownService: ObservableObject {
    @Published var remainingTime: TimeInterval?
    @Published var formattedTime: String = ""
    @Published var isActive: Bool = false
    
    private var timer: Timer?
    private var targetDate: Date?
    private var onCountdownComplete: (() -> Void)?
    
    func startCountdown(to date: Date, onComplete: (() -> Void)? = nil) {
        stopCountdown() // Stop any existing countdown
        
        targetDate = date
        onCountdownComplete = onComplete
        isActive = true
        
        // Start timer with appropriate interval
        updateDisplay()
        scheduleNextUpdate()
    }
    
    func stopCountdown() {
        timer?.invalidate()
        timer = nil
        targetDate = nil
        remainingTime = nil
        formattedTime = ""
        isActive = false
        onCountdownComplete = nil
    }
    
    private func updateDisplay() {
        guard let targetDate = targetDate else {
            stopCountdown()
            return
        }
        
        let now = Date()
        let timeInterval = targetDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            // Countdown finished
            stopCountdown()
            onCountdownComplete?()
            return
        }
        
        remainingTime = timeInterval
        formattedTime = formatTimeInterval(timeInterval)
    }
    
    private func scheduleNextUpdate() {
        guard let targetDate = targetDate else { return }
        
        let now = Date()
        let timeInterval = targetDate.timeIntervalSince(now)
        
        // Optimize update intervals for better performance
        var updateInterval: TimeInterval
        
        if timeInterval > 3600 { // More than 1 hour
            updateInterval = 60 // Update every minute
        } else if timeInterval > 600 { // More than 10 minutes
            updateInterval = 30 // Update every 30 seconds
        } else if timeInterval > 60 { // More than 1 minute
            updateInterval = 10 // Update every 10 seconds
        } else { // Less than 1 minute
            updateInterval = 1 // Update every second
        }
        
        // Use more efficient timer scheduling
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateDisplay()
                self?.scheduleNextUpdate()
            }
        }
        
        // Ensure timer runs in common run loop modes for better responsiveness
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else if minutes > 0 {
            if minutes >= 10 {
                return "\(minutes)m"
            } else {
                // Show seconds for final 10 minutes
                return "\(minutes):\(String(format: "%02d", seconds))"
            }
        } else {
            return "0:\(String(format: "%02d", seconds))"
        }
    }
    
    // Helper method to get detailed time breakdown
    func getTimeComponents() -> (hours: Int, minutes: Int, seconds: Int)? {
        guard let remainingTime = remainingTime else { return nil }
        
        let totalSeconds = Int(remainingTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return (hours, minutes, seconds)
    }
    
    // Check if countdown is in critical phase (less than 10 minutes)
    var isCritical: Bool {
        guard let remainingTime = remainingTime else { return false }
        return remainingTime <= 600 // 10 minutes
    }
    
    // Check if countdown is in final phase (less than 1 minute)
    var isFinal: Bool {
        guard let remainingTime = remainingTime else { return false }
        return remainingTime <= 60 // 1 minute
    }
}