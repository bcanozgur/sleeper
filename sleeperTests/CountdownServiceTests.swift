//
//  CountdownServiceTests.swift
//  sleeperTests
//
//  Created by Berkecan Özgür on 17.11.2022.
//

import XCTest
@testable import sleeper

final class CountdownServiceTests: XCTestCase {
    var countdownService: CountdownService!
    
    override func setUp() {
        super.setUp()
        countdownService = CountdownService()
    }
    
    override func tearDown() {
        countdownService.stopCountdown()
        countdownService = nil
        super.tearDown()
    }
    
    func testCountdownInitialState() {
        XCTAssertFalse(countdownService.isActive)
        XCTAssertNil(countdownService.remainingTime)
        XCTAssertEqual(countdownService.formattedTime, "")
    }
    
    func testStartCountdown() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        
        countdownService.startCountdown(to: futureDate)
        
        XCTAssertTrue(countdownService.isActive)
        XCTAssertNotNil(countdownService.remainingTime)
        XCTAssertFalse(countdownService.formattedTime.isEmpty)
    }
    
    func testStopCountdown() {
        let futureDate = Date().addingTimeInterval(3600)
        countdownService.startCountdown(to: futureDate)
        
        countdownService.stopCountdown()
        
        XCTAssertFalse(countdownService.isActive)
        XCTAssertNil(countdownService.remainingTime)
        XCTAssertEqual(countdownService.formattedTime, "")
    }
    
    func testTimeFormatting() {
        // Test various time intervals
        let testCases: [(TimeInterval, String)] = [
            (3661, "1h 1m"),    // 1 hour 1 minute 1 second
            (3600, "1h"),       // 1 hour exactly
            (600, "10m"),       // 10 minutes
            (65, "1:05"),       // 1 minute 5 seconds
            (30, "0:30"),       // 30 seconds
            (5, "0:05")         // 5 seconds
        ]
        
        for (interval, expected) in testCases {
            let futureDate = Date().addingTimeInterval(interval)
            countdownService.startCountdown(to: futureDate)
            
            // Allow a small margin for timing differences
            let formatted = countdownService.formattedTime
            XCTAssertTrue(formatted.hasPrefix(expected.prefix(expected.count - 1)), 
                         "Expected format starting with \(expected.prefix(expected.count - 1)), got \(formatted)")
        }
    }
    
    func testCriticalPhase() {
        // Test critical phase (less than 10 minutes)
        let criticalDate = Date().addingTimeInterval(300) // 5 minutes
        countdownService.startCountdown(to: criticalDate)
        
        XCTAssertTrue(countdownService.isCritical)
        XCTAssertFalse(countdownService.isFinal)
    }
    
    func testFinalPhase() {
        // Test final phase (less than 1 minute)
        let finalDate = Date().addingTimeInterval(30) // 30 seconds
        countdownService.startCountdown(to: finalDate)
        
        XCTAssertTrue(countdownService.isCritical)
        XCTAssertTrue(countdownService.isFinal)
    }
    
    func testTimeComponents() {
        let futureDate = Date().addingTimeInterval(3665) // 1h 1m 5s
        countdownService.startCountdown(to: futureDate)
        
        guard let components = countdownService.getTimeComponents() else {
            XCTFail("Time components should not be nil")
            return
        }
        
        XCTAssertEqual(components.hours, 1)
        XCTAssertEqual(components.minutes, 1)
        // Seconds might vary slightly due to timing
        XCTAssertTrue(components.seconds >= 0 && components.seconds <= 10)
    }
}