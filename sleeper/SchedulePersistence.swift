//
//  SchedulePersistence.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import Foundation

struct ScheduleData: Codable {
    let scheduledDate: Date
    let isActive: Bool
    let createdAt: Date
}

class SchedulePersistence {
    static let shared = SchedulePersistence()
    
    private let userDefaults = UserDefaults.standard
    private let scheduleKey = "com.sleeper.currentSchedule"
    
    private init() {}
    
    func saveSchedule(_ scheduleData: ScheduleData) {
        do {
            let data = try JSONEncoder().encode(scheduleData)
            userDefaults.set(data, forKey: scheduleKey)
            userDefaults.synchronize()
        } catch {
            print("Failed to save schedule: \(error)")
        }
    }
    
    func loadSchedule() -> ScheduleData? {
        guard let data = userDefaults.data(forKey: scheduleKey) else { return nil }
        
        do {
            let scheduleData = try JSONDecoder().decode(ScheduleData.self, from: data)
            
            // Check if schedule is still valid (not in the past)
            if scheduleData.scheduledDate > Date() && scheduleData.isActive {
                return scheduleData
            } else {
                // Clean up expired schedule
                clearSchedule()
                return nil
            }
        } catch {
            print("Failed to load schedule: \(error)")
            clearSchedule()
            return nil
        }
    }
    
    func clearSchedule() {
        userDefaults.removeObject(forKey: scheduleKey)
        userDefaults.synchronize()
    }
    
    func hasActiveSchedule() -> Bool {
        return loadSchedule() != nil
    }
}