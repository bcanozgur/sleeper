//
//  DateUtilitiesTests.swift
//  sleeperTests
//
//  Created by Berkecan Özgür on 17.11.2022.
//

import XCTest
@testable import sleeper

final class DateUtilitiesTests: XCTestCase {
    
    func testFormatForPmset() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 12, day: 25, hour: 14, minute: 30, second: 0)
        let testDate = calendar.date(from: components)!
        
        let formatted = DateUtilities.formatForPmset(date: testDate)
        XCTAssertTrue(formatted.contains("12/25/24 14:30:00"))
    }
    
    func testIsValidFutureDate() {
        let futureDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
        let pastDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date.now)!
        
        XCTAssertTrue(DateUtilities.isValidFutureDate(futureDate))
        XCTAssertFalse(DateUtilities.isValidFutureDate(pastDate))
    }
    
    func testValidateScheduleDate() {
        let futureDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
        let pastDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date.now)!
        let farFutureDate = Calendar.current.date(byAdding: .year, value: 2, to: Date.now)!
        
        XCTAssertNil(DateUtilities.validateScheduleDate(futureDate))
        XCTAssertNotNil(DateUtilities.validateScheduleDate(pastDate))
        XCTAssertNotNil(DateUtilities.validateScheduleDate(farFutureDate))
    }
    
    func testMinimumSelectableDate() {
        let minDate = DateUtilities.minimumSelectableDate()
        XCTAssertTrue(minDate > Date.now)
    }
}