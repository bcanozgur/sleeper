//
//  PerformanceMonitor.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import Foundation
import Darwin

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var lastMemoryCheck = Date()
    private let memoryCheckInterval: TimeInterval = 30 // Check every 30 seconds
    
    private init() {}
    
    func checkMemoryUsage() {
        let now = Date()
        guard now.timeIntervalSince(lastMemoryCheck) >= memoryCheckInterval else { return }
        
        lastMemoryCheck = now
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = info.resident_size / 1024 / 1024 // Convert to MB
            
            #if DEBUG
            print("Memory usage: \(memoryUsage) MB")
            #endif
            
            // Log warning if memory usage is high (over 50MB for a menu bar app)
            if memoryUsage > 50 {
                print("Warning: High memory usage detected: \(memoryUsage) MB")
            }
        }
    }
    
    func optimizeForBackground() {
        // Reduce timer precision when app is in background
        DispatchQueue.global(qos: .background).async {
            // Perform any background cleanup tasks
        }
    }
}