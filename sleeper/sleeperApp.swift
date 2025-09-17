//
//  sleeperApp.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import SwiftUI
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    var scheduleManager: MenuBarScheduleManager?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hide dock icon and main window
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize schedule manager
        scheduleManager = MenuBarScheduleManager()
        
        // Initialize menu bar
        menuBarManager = MenuBarManager()
        
        // Connect menu bar manager with schedule manager
        scheduleManager?.menuBarManager = menuBarManager
        
        // Set up menu bar callbacks
        menuBarManager?.onSchedule = { [weak self] date in
            self?.scheduleManager?.scheduleNewSleep(for: date)
        }
        
        menuBarManager?.onCancel = { [weak self] in
            self?.scheduleManager?.cancelCurrentSchedule()
        }
        
        // Hide all windows
        for window in NSApplication.shared.windows {
            window.close()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        scheduleManager?.cancelCurrentSchedule()
        scheduleManager = nil
        menuBarManager = nil
    }
}

@main
struct MacSleepSchedulerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}