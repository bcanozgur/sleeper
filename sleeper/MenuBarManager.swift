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
    
    init() {
        setupMenuBar()
        setupPopover()
    }
    
    func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            print("Failed to create status bar item")
            return
        }
        
        // Set default icon and title
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Sleep Scheduler")
            button.image?.isTemplate = true // Ensures proper dark/light mode handling
            button.toolTip = "Mac Sleep Scheduler - Click to schedule sleep"
            button.action = #selector(togglePopover)
            button.target = self
            
            // Enable right-click for additional options
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        isMenuBarActive = true
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
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        if appDelegate?.scheduleManager?.isScheduleActive == true {
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
            iconName = "clock.badge.plus"
            accessibilityDescription = "Sleep Scheduler - Scheduling"
            toolTip = "Mac Sleep Scheduler - Scheduling in progress..."
        case .active:
            iconName = "clock.badge.checkmark"
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
            
            // Only update menu content if popover is currently shown
            if self.popover?.isShown == true {
                self.updateMenuContent()
            }
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
        
        // Get schedule info from app delegate
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        let scheduleManager = appDelegate?.scheduleManager
        
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
            isScheduleActive: scheduleManager?.isScheduleActive ?? false,
            scheduleInfo: scheduleManager?.getScheduleInfo(),
            canSchedule: scheduleManager?.canSchedule ?? true
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