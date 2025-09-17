//
//  SystemEventMonitor.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import Foundation
import IOKit.pwr_mgt
import IOKit

class SystemEventMonitor {
    static let shared = SystemEventMonitor()
    
    private var sleepNotificationPort: IONotificationPortRef?
    private var sleepNotifier: io_object_t = 0
    private var wakeNotifier: io_object_t = 0
    
    var onSystemSleep: (() -> Void)?
    var onSystemWake: (() -> Void)?
    
    private init() {
        setupSleepWakeNotifications()
    }
    
    private func setupSleepWakeNotifications() {
        sleepNotificationPort = IONotificationPortCreate(kIOMainPortDefault)
        
        guard let notificationPort = sleepNotificationPort else {
            print("Failed to create sleep notification port")
            return
        }
        
        let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource?.takeUnretainedValue(), CFRunLoopMode.commonModes)
        
        // Register for sleep notifications
        let sleepCallback: IOServiceInterestCallback = { (refcon, service, messageType, messageArgument) in
            let monitor = Unmanaged<SystemEventMonitor>.fromOpaque(refcon!).takeUnretainedValue()
            
            switch messageType {
            case 0x270: // kIOMessageCanSystemSleep
                // System is asking if it can sleep
                IOAllowPowerChange(IONotificationPortGetMachPort(monitor.sleepNotificationPort), Int(bitPattern: messageArgument))
                
            case 0x280: // kIOMessageSystemWillSleep
                // System is going to sleep
                monitor.onSystemSleep?()
                IOAllowPowerChange(IONotificationPortGetMachPort(monitor.sleepNotificationPort), Int(bitPattern: messageArgument))
                
            case 0x230: // kIOMessageSystemHasPoweredOn
                // System has woken up
                monitor.onSystemWake?()
                
            default:
                break
            }
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        IOServiceAddInterestNotification(
            notificationPort,
            IORegistryEntryFromPath(kIOMainPortDefault, "IOPowerPlane:/IOPowerConnection/IOPMrootDomain"),
            kIOGeneralInterest,
            sleepCallback,
            selfPtr,
            &sleepNotifier
        )
    }
    
    deinit {
        if sleepNotifier != 0 {
            IOObjectRelease(sleepNotifier)
        }
        if wakeNotifier != 0 {
            IOObjectRelease(wakeNotifier)
        }
        if let notificationPort = sleepNotificationPort {
            IONotificationPortDestroy(notificationPort)
        }
    }
}