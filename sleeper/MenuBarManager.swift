//
//  MenuBarManager.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import SwiftUI
import AppKit

enum MenuBarState: Equatable {
    case idle
    case scheduling
    case activeCountdown(Date)
    case error(String)
}

enum MenuBarIconState {
    case idle
    case scheduling
    case active
    case warning
    case error
}

class MenuBarManager: ObservableObject {
    private(set) var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    @Published var isMenuBarActive = false
    @Published var currentState: MenuBarState = .idle
    
    // Callbacks for menu actions
    var onSchedule: ((Date) -> Void)?
    var onCancel: (() -> Void)?
    var onCountdownComplete: (() -> Void)?
    
    // Schedule manager reference
    weak var scheduleManager: MenuBarScheduleManager?
    
    // Countdown properties
    private var countdownTimer: Timer?
    private var scheduledDate: Date?
    
    init() {
        setupMenuBar()
        setupPopover()
    }
    
    func setupMenuBar() {
        // Ensure we're on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.createMenuBarItem()
        }
    }
    
    private func createMenuBarItem() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            print("❌ Failed to create status bar item")
            return
        }
        
        // Set default icon and title
        if let button = statusItem.button {
            // Use a nice moon icon for sleep scheduler
            if let moonImage = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Sleep Scheduler") {
                button.image = moonImage
                button.image?.isTemplate = true
                button.imagePosition = .imageOnly
            } else if let moonImage = NSImage(systemSymbolName: "moon", accessibilityDescription: "Sleep Scheduler") {
                button.image = moonImage
                button.image?.isTemplate = true
                button.imagePosition = .imageOnly
            } else {
                // Fallback to emoji
                button.title = "💤"
                button.font = NSFont.systemFont(ofSize: 16)
            }
            
            // Alternative: try system symbol with custom size
            /*
            if let moonImage = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Sleep Scheduler") {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                let resizedImage = moonImage.withSymbolConfiguration(config)
                button.image = resizedImage
                button.image?.isTemplate = true
                iconSet = true
                print("✅ Using moon.zzz system symbol with custom size")
            }
            */
            
            // Icon setup completed
            
            button.toolTip = "Mac Sleep Scheduler - Click to schedule sleep"
            button.action = #selector(togglePopover)
            button.target = self
            
            // Enable right-click for additional options
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // Menu bar button configured
        } else {
            print("❌ Failed to get status bar button")
        }
        
        isMenuBarActive = true
        
        // Force a refresh of the status bar
        statusItem.button?.needsDisplay = true
        
        // Try to make it more visible and persistent
        statusItem.button?.alphaValue = 1.0
        statusItem.isVisible = true
        statusItem.autosaveName = "SleeperMenuBarItem"
        
        // Keep menu bar visible with periodic check
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.ensureVisible()
        }
        
        // Also force refresh immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.forceRefresh()
        }
    }
    
    func forceMenuBarVisible() {
        guard let statusItem = statusItem else { return }
        
        // Re-create the status item if needed
        if statusItem.button == nil {
            setupMenuBar()
            return
        }
        
        // Force visibility
        statusItem.isVisible = true
        statusItem.button?.isHidden = false
        statusItem.button?.alphaValue = 1.0
        statusItem.button?.needsDisplay = true
    }
    
    private func ensureVisible() {
        guard let statusItem = statusItem else { 
            setupMenuBar()
            return 
        }
        
        // If it's not visible, recreate the entire status item
        if !statusItem.isVisible || statusItem.button?.isHidden == true {
            // Remove old status item
            NSStatusBar.system.removeStatusItem(statusItem)
            
            // Create new one
            setupMenuBar()
            return
        }
    }
    
    private func forceRefresh() {
        guard let statusItem = statusItem else { return }
        
        // Force the button to redraw
        statusItem.button?.needsDisplay = true
        statusItem.button?.display()
        
        // Try to force the status bar to refresh
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Recreate the button with icon
        if let button = self.statusItem?.button {
            if let moonImage = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Sleep Scheduler") {
                button.image = moonImage
                button.image?.isTemplate = true
                button.imagePosition = .imageOnly
                button.title = ""
            } else {
                button.title = "💤"
                button.font = NSFont.systemFont(ofSize: 16)
            }
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        

    }
    
    // MARK: - Countdown Functions
    
    func startCountdown(to date: Date) {
        scheduledDate = date
        countdownTimer?.invalidate()
        
        // Update immediately
        updateCountdownDisplay()
        
        // Start timer to update every second
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdownDisplay()
        }
        

    }
    
    func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        scheduledDate = nil
        
        // Reset to default icon
        resetToDefaultIcon()
        

    }
    
    private func updateCountdownDisplay() {
        guard let scheduledDate = scheduledDate,
              let button = statusItem?.button else { return }
        
        let now = Date()
        
        // Since pmset works with minute precision, calculate time to the exact minute
        let calendar = Calendar.current
        let scheduledComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let exactScheduledDate = calendar.date(from: scheduledComponents) ?? scheduledDate
        
        let timeInterval = exactScheduledDate.timeIntervalSince(now)
        
        // If time has passed, stop countdown and notify
        if timeInterval <= 0 {
            stopCountdown()
            onCountdownComplete?()
            return
        }
        
        // Format time remaining
        let timeString = formatTimeRemaining(timeInterval)
        
        // Update button with icon + countdown
        if let moonImage = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Sleep Scheduler") {
            button.image = moonImage
            button.image?.isTemplate = true
            button.title = " \(timeString)" // Space before time for better spacing
            button.imagePosition = .imageLeft
        } else {
            button.title = "💤 \(timeString)"
            button.image = nil
        }
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        
        // Change color based on urgency
        if timeInterval < 60 { // Less than 1 minute - red
            button.contentTintColor = NSColor.systemRed
        } else if timeInterval < 600 { // Less than 10 minutes - orange
            button.contentTintColor = NSColor.systemOrange
        } else {
            button.contentTintColor = NSColor.controlTextColor
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    private func resetToDefaultIcon() {
        guard let button = statusItem?.button else { return }
        
        // Reset to moon icon
        if let moonImage = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Sleep Scheduler") {
            button.image = moonImage
            button.image?.isTemplate = true
            button.title = ""
            button.imagePosition = .imageOnly
        } else {
            button.title = "💤"
            button.image = nil
            button.font = NSFont.systemFont(ofSize: 16)
        }
        
        button.contentTintColor = nil // Reset color
    }
    

    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 200)
        popover?.behavior = .transient
        // Initial content will be updated by updateMenuContent()
        popover?.contentViewController = NSHostingController(
            rootView: MenuContentView(
                onSchedule: { [weak self] date in
                    self?.handleSchedule(date)
                },
                onCancel: { [weak self] in
                    self?.handleCancel()
                },
                onQuit: { [weak self] in
                    self?.handleQuit()
                }
            )
        )
    }
    
    @objc func togglePopover() {
        guard let statusItem = statusItem,
              let button = statusItem.button,
              let popover = popover else { return }
        
        // Handle right-click for quick actions
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showQuickActionsMenu()
            return
        }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Update menu content before showing for better performance
            updateMenuContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Ensure popover gets focus for keyboard navigation
            popover.contentViewController?.view.window?.makeFirstResponder(popover.contentViewController?.view)
        }
    }
    
    private func showQuickActionsMenu() {
        let menu = NSMenu()
        
        // Quick schedule options
        let quickScheduleMenu = NSMenu()
        
        let in30Minutes = NSMenuItem(title: "Sleep in 30 minutes", action: #selector(scheduleIn30Minutes), keyEquivalent: "")
        in30Minutes.target = self
        quickScheduleMenu.addItem(in30Minutes)
        
        let in1Hour = NSMenuItem(title: "Sleep in 1 hour", action: #selector(scheduleIn1Hour), keyEquivalent: "")
        in1Hour.target = self
        quickScheduleMenu.addItem(in1Hour)
        
        let in2Hours = NSMenuItem(title: "Sleep in 2 hours", action: #selector(scheduleIn2Hours), keyEquivalent: "")
        in2Hours.target = self
        quickScheduleMenu.addItem(in2Hours)
        
        let quickScheduleItem = NSMenuItem(title: "Quick Schedule", action: nil, keyEquivalent: "")
        quickScheduleItem.submenu = quickScheduleMenu
        menu.addItem(quickScheduleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Cancel current schedule if active
        if scheduleManager?.isScheduleActive == true {
            let cancelItem = NSMenuItem(title: "Cancel Current Schedule", action: #selector(handleCancel), keyEquivalent: "")
            cancelItem.target = self
            menu.addItem(cancelItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Quit option
        let quitItem = NSMenuItem(title: "Quit Sleep Scheduler", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Show context menu
        if let button = statusItem?.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        }
    }
    
    @objc private func scheduleIn30Minutes() {
        let date = Date().addingTimeInterval(30 * 60)
        handleSchedule(date)
    }
    
    @objc private func scheduleIn1Hour() {
        let date = Date().addingTimeInterval(60 * 60)
        handleSchedule(date)
    }
    
    @objc private func scheduleIn2Hours() {
        let date = Date().addingTimeInterval(2 * 60 * 60)
        handleSchedule(date)
    }
    
    func updateMenuBarTitle(_ text: String) {
        guard let statusItem = statusItem else { return }
        
        // Avoid unnecessary updates if text hasn't changed
        if let button = statusItem.button, button.title == text {
            return
        }
        
        DispatchQueue.main.async {
            if let button = statusItem.button {
                if text.isEmpty {
                    // Show default icon only
                    self.setMenuBarIcon(.idle)
                    button.title = ""
                    button.attributedTitle = NSAttributedString(string: "")
                } else {
                    // Show countdown text with appropriate styling
                    button.image = nil
                    
                    // Change text color based on urgency (optimized)
                    let attributes: [NSAttributedString.Key: Any]
                    if text.contains(":") && !text.contains("h") && !text.contains("m") {
                        // Final countdown (showing seconds)
                        attributes = [.foregroundColor: NSColor.systemRed]
                    } else if text.contains(":") {
                        // Critical phase (less than 10 minutes)
                        attributes = [.foregroundColor: NSColor.systemOrange]
                    } else {
                        // Normal countdown
                        attributes = [.foregroundColor: NSColor.controlTextColor]
                    }
                    
                    button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
                }
            }
        }
    }
    
    private func setMenuBarIcon(_ state: MenuBarIconState) {
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }
        
        let iconName: String
        let accessibilityDescription: String
        let toolTip: String
        
        switch state {
        case .idle:
            iconName = "moon.zzz"
            accessibilityDescription = "Sleep Scheduler - Idle"
            toolTip = "Mac Sleep Scheduler - Click to schedule sleep"
        case .scheduling:
            iconName = "clock"
            accessibilityDescription = "Sleep Scheduler - Scheduling"
            toolTip = "Mac Sleep Scheduler - Scheduling in progress..."
        case .active:
            iconName = "checkmark.circle"
            accessibilityDescription = "Sleep Scheduler - Active"
            toolTip = "Mac Sleep Scheduler - Sleep scheduled (click for details)"
        case .warning:
            iconName = "clock.badge.exclamationmark"
            accessibilityDescription = "Sleep Scheduler - Warning"
            toolTip = "Mac Sleep Scheduler - Sleep soon! (click for options)"
        case .error:
            iconName = "exclamationmark.triangle"
            accessibilityDescription = "Sleep Scheduler - Error"
            toolTip = "Mac Sleep Scheduler - Error occurred (click for details)"
        }
        
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: accessibilityDescription)
        button.image?.isTemplate = true
        button.toolTip = toolTip
        
        // Add subtle color tinting for different states
        switch state {
        case .active:
            button.contentTintColor = NSColor.systemGreen
        case .warning:
            button.contentTintColor = NSColor.systemOrange
        case .error:
            button.contentTintColor = NSColor.systemRed
        default:
            button.contentTintColor = nil
        }
    }
    
    func updateState(_ newState: MenuBarState) {
        guard currentState != newState else { return }
        
        DispatchQueue.main.async {
            self.currentState = newState
            self.updateIconForState(newState)
            
            // Always update menu content when state changes
            // This ensures the popover shows correct info when opened
            self.updateMenuContent()
        }
    }
    
    private func updateIconForState(_ state: MenuBarState) {
        let iconState: MenuBarIconState
        
        switch state {
        case .idle:
            iconState = .idle
        case .scheduling:
            iconState = .scheduling
        case .activeCountdown:
            iconState = .active
        case .error:
            iconState = .error
        }
        
        setMenuBarIcon(iconState)
    }
    
    private func updateMenuContent() {
        // Update popover content based on state
        guard let popover = popover else { return }
        
        // Use direct reference to schedule manager
        let isActive = scheduleManager?.isScheduleActive ?? false
        let scheduleInfo = scheduleManager?.getScheduleInfo()
        let canSchedule = scheduleManager?.canSchedule ?? true
        
        let contentView = MenuContentView(
            onSchedule: { [weak self] date in
                self?.handleSchedule(date)
            },
            onCancel: { [weak self] in
                self?.handleCancel()
            },
            onQuit: { [weak self] in
                self?.handleQuit()
            },
            isScheduleActive: isActive,
            scheduleInfo: scheduleInfo,
            canSchedule: canSchedule
        )
        
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func handleSchedule(_ date: Date) {
        popover?.performClose(nil)
        onSchedule?(date)
    }
    
    @objc private func handleCancel() {
        popover?.performClose(nil)
        onCancel?()
    }
    
    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}