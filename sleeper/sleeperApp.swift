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
        // Initialize components
        menuBarManager = MenuBarManager()
        scheduleManager = MenuBarScheduleManager()
        
        // Connect components (bidirectional)
        scheduleManager?.menuBarManager = menuBarManager
        menuBarManager?.scheduleManager = scheduleManager
        
        // Set up callbacks
        menuBarManager?.onSchedule = { [weak self] date in
            self?.scheduleManager?.scheduleNewSleep(for: date)
        }
        
        menuBarManager?.onCancel = { [weak self] in
            self?.scheduleManager?.cancelCurrentSchedule()
        }
        
        // Hide windows
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                window.close()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Cancel current schedule through the schedule manager
        if let scheduleManager = scheduleManager, scheduleManager.isScheduleActive {
            scheduleManager.cancelCurrentSchedule()
        }
        
        scheduleManager = nil
        menuBarManager = nil
    }
    

}

@main
struct MacSleepSchedulerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // For menu bar only apps, we need at least one scene but we'll hide it
        Settings {
            EmptyView()
        }
    }
}