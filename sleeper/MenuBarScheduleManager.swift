//
//  MenuBarScheduleManager.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import Foundation
import Combine
import Cocoa

class MenuBarScheduleManager: ObservableObject {
    @Published var isScheduleActive = false
    @Published var scheduledDate: Date?
    @Published var currentState: MenuBarState = .idle
    
    private let sleepSchedulerService = SleepSchedulerService()
    private let countdownService = CountdownService()
    private var cancellables = Set<AnyCancellable>()
    
    weak var menuBarManager: MenuBarManager?
    
    // Expose statusItem for direct access when needed
    var statusItem: NSStatusItem? {
        return menuBarManager?.statusItem
    }
    
    init() {
        setupBindings()
        setupSystemEventMonitoring()
        restoreScheduleFromPersistence()
    }
    
    private func setupBindings() {
        // Listen to sleep scheduler service state changes
        sleepSchedulerService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleSchedulerStateChange(state)
            }
            .store(in: &cancellables)
        
        // Listen to countdown service updates
        countdownService.$formattedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] formattedTime in
                self?.updateMenuBarDisplay(formattedTime)
            }
            .store(in: &cancellables)
        
        // Listen to countdown completion
        countdownService.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                if !isActive && self?.isScheduleActive == true {
                    // Countdown finished
                    self?.handleCountdownComplete()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSystemEventMonitoring() {
        SystemEventMonitor.shared.onSystemSleep = {
            // System is going to sleep - countdown will pause automatically
        }
        
        SystemEventMonitor.shared.onSystemWake = { [weak self] in
            // System woke up - restore countdown if needed
            if let self = self, self.isScheduleActive, let scheduledDate = self.scheduledDate {
                // System woke up - restore countdown
                
                // Check if scheduled time has passed while system was asleep
                if scheduledDate <= Date() {
                    // Schedule time has passed - reset everything
                    self.handleCountdownComplete()
                } else {
                    // Restart countdown
                    self.countdownService.startCountdown(to: scheduledDate) {
                        self.handleCountdownComplete()
                    }
                }
            }
        }
    }
    
    private func restoreScheduleFromPersistence() {
        guard let scheduleData = SchedulePersistence.shared.loadSchedule() else { return }
        
        // Restore schedule state
        scheduledDate = scheduleData.scheduledDate
        isScheduleActive = true
        currentState = .activeCountdown(scheduleData.scheduledDate)
        
        // Start countdown
        countdownService.startCountdown(to: scheduleData.scheduledDate) { [weak self] in
            self?.handleCountdownComplete()
        }
        
        // Update menu bar
        menuBarManager?.updateState(.activeCountdown(scheduleData.scheduledDate))
        
        // Schedule restored from persistence
    }
    
    private func persistCurrentSchedule() {
        guard let scheduledDate = scheduledDate, isScheduleActive else {
            SchedulePersistence.shared.clearSchedule()
            return
        }
        
        let scheduleData = ScheduleData(
            scheduledDate: scheduledDate,
            isActive: isScheduleActive,
            createdAt: Date()
        )
        
        SchedulePersistence.shared.saveSchedule(scheduleData)
    }
    
    func scheduleNewSleep(for date: Date) {
        currentState = .scheduling
        menuBarManager?.updateState(.scheduling)
        
        // Validate date
        if let validationError = DateUtilities.validateScheduleDate(date) {
            currentState = .error(validationError)
            menuBarManager?.updateState(.error(validationError))
            return
        }
        
        // Schedule with sleep scheduler service
        sleepSchedulerService.scheduleSleep(for: date)
        
        // Store scheduled date
        scheduledDate = date
    }
    
    func cancelCurrentSchedule() {
        // Cancel pmset schedule first
        cancelPmsetSchedule()
        
        // Reset state
        isScheduleActive = false
        scheduledDate = nil
        currentState = .idle
        
        // Update menu bar
        menuBarManager?.updateState(.idle)
        menuBarManager?.updateMenuBarTitle("")
        menuBarManager?.stopCountdown()
        
        // Clear persisted schedule
        SchedulePersistence.shared.clearSchedule()
        
        // Schedule cancelled successfully
    }
    
    private func handleSchedulerStateChange(_ state: SchedulingState) {
        switch state {
        case .idle:
            currentState = .idle
            menuBarManager?.updateState(.idle)
            
        case .scheduling:
            currentState = .scheduling
            menuBarManager?.updateState(.scheduling)
            
        case .success(_):
            // Schedule was successful, start countdown
            if let scheduledDate = scheduledDate {
                isScheduleActive = true
                currentState = .activeCountdown(scheduledDate)
                menuBarManager?.updateState(.activeCountdown(scheduledDate))
                
                // Start countdown timer in menu bar
                menuBarManager?.startCountdown(to: scheduledDate)
                
                // Set up completion callback for menu bar countdown
                menuBarManager?.onCountdownComplete = { [weak self] in
                    self?.handleCountdownComplete()
                }
                
                // Persist the schedule
                persistCurrentSchedule()
                

            }
            
        case .error(let errorMessage):
            currentState = .error(errorMessage)
            menuBarManager?.updateState(.error(errorMessage))
            
            // Reset after showing error
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.currentState = .idle
                self?.menuBarManager?.updateState(.idle)
            }
        }
    }
    
    private func updateMenuBarDisplay(_ formattedTime: String) {
        if isScheduleActive && !formattedTime.isEmpty {
            menuBarManager?.updateMenuBarTitle(formattedTime)
            
            // Update icon state based on remaining time
            if countdownService.isFinal {
                // Less than 1 minute - show warning state
                menuBarManager?.updateState(.activeCountdown(scheduledDate!))
                if let button = menuBarManager?.statusItem?.button {
                    button.contentTintColor = NSColor.systemRed
                }
            } else if countdownService.isCritical {
                // Less than 10 minutes - show orange state
                if let button = menuBarManager?.statusItem?.button {
                    button.contentTintColor = NSColor.systemOrange
                }
            }
        }
    }
    
    private func handleCountdownComplete() {
        // Reset everything when countdown completes
        isScheduleActive = false
        scheduledDate = nil
        currentState = .idle
        
        menuBarManager?.updateState(.idle)
        menuBarManager?.updateMenuBarTitle("")
        
        // Clear persisted schedule
        SchedulePersistence.shared.clearSchedule()
    }
    
    private func cancelPmsetSchedule() {
        // Execute pmset command to cancel all scheduled sleep events
        let cancelCommand = "pmset schedule cancelall"
        let nsScriptCommand = "do shell script \"\(cancelCommand)\" with administrator privileges"
        
        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: nsScriptCommand)
        let _ = scriptObject?.executeAndReturnError(&error)
        
        if let errorDict = error {
            print("❌ Error canceling pmset schedule: \(errorDict)")
        }
    }
    
    // Get current schedule info for display
    func getScheduleInfo() -> String? {
        guard let scheduledDate = scheduledDate, isScheduleActive else { return nil }
        return "Next sleep: \(DateUtilities.formatForDisplay(date: scheduledDate))"
    }
    
    // Check if we can schedule (not currently scheduling or active)
    var canSchedule: Bool {
        switch currentState {
        case .idle:
            return true
        case .scheduling, .activeCountdown, .error:
            return false
        }
    }
}