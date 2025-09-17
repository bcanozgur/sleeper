//
//  SchedulePersistenceTests.swift
//  sleeperTests
//
//  Created by Berkecan Özgür on 17.11.2022.
//

import XCTest
@testable import sleeper

final class SchedulePersistenceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing schedule data
        SchedulePersistence.shared.clearSchedule()
    }
    
    override func tearDown() {
        // Clean up after tests
        SchedulePersistence.shared.clearSchedule()
        super.tearDown()
    }
    
    func testSaveAndLoadSchedule() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let scheduleData = ScheduleData(
            scheduledDate: futureDate,
            isActive: true,
            createdAt: Date()
        )
        
        // Save schedule
        SchedulePersistence.shared.saveSchedule(scheduleData)
        
        // Load schedule
        let loadedSchedule = SchedulePersistence.shared.loadSchedule()
        
        XCTAssertNotNil(loadedSchedule)
        XCTAssertEqual(loadedSchedule?.scheduledDate.timeIntervalSince1970, 
                      scheduleData.scheduledDate.timeIntervalSince1970, 
                      accuracy: 1.0)
        XCTAssertEqual(loadedSchedule?.isActive, scheduleData.isActive)
    }
    
    func testLoadNonExistentSchedule() {
        let loadedSchedule = SchedulePersistence.shared.loadSchedule()
        XCTAssertNil(loadedSchedule)
    }
    
    func testExpiredScheduleIsCleared() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let expiredSchedule = ScheduleData(
            scheduledDate: pastDate,
            isActive: true,
            createdAt: Date().addingTimeInterval(-7200) // 2 hours ago
        )
        
        // Save expired schedule
        SchedulePersistence.shared.saveSchedule(expiredSchedule)
        
        // Try to load - should return nil and clear the expired data
        let loadedSchedule = SchedulePersistence.shared.loadSchedule()
        XCTAssertNil(loadedSchedule)
        
        // Verify it was cleared
        XCTAssertFalse(SchedulePersistence.shared.hasActiveSchedule())
    }
    
    func testClearSchedule() {
        let futureDate = Date().addingTimeInterval(3600)
        let scheduleData = ScheduleData(
            scheduledDate: futureDate,
            isActive: true,
            createdAt: Date()
        )
        
        // Save schedule
        SchedulePersistence.shared.saveSchedule(scheduleData)
        XCTAssertTrue(SchedulePersistence.shared.hasActiveSchedule())
        
        // Clear schedule
        SchedulePersistence.shared.clearSchedule()
        XCTAssertFalse(SchedulePersistence.shared.hasActiveSchedule())
        XCTAssertNil(SchedulePersistence.shared.loadSchedule())
    }
    
    func testHasActiveSchedule() {
        // Initially should have no active schedule
        XCTAssertFalse(SchedulePersistence.shared.hasActiveSchedule())
        
        // Save a schedule
        let futureDate = Date().addingTimeInterval(3600)
        let scheduleData = ScheduleData(
            scheduledDate: futureDate,
            isActive: true,
            createdAt: Date()
        )
        SchedulePersistence.shared.saveSchedule(scheduleData)
        
        // Should now have active schedule
        XCTAssertTrue(SchedulePersistence.shared.hasActiveSchedule())
    }
}