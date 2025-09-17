//
//  MenuBarManagerTests.swift
//  sleeperTests
//
//  Created by Berkecan Özgür on 17.11.2022.
//

import XCTest
@testable import sleeper

final class MenuBarManagerTests: XCTestCase {
    var menuBarManager: MenuBarManager!
    
    override func setUp() {
        super.setUp()
        menuBarManager = MenuBarManager()
    }
    
    override func tearDown() {
        menuBarManager = nil
        super.tearDown()
    }
    
    func testMenuBarInitialization() {
        XCTAssertTrue(menuBarManager.isMenuBarActive)
        XCTAssertNotNil(menuBarManager.statusItem)
        XCTAssertEqual(menuBarManager.currentState, .idle)
    }
    
    func testStateUpdates() {
        let expectation = XCTestExpectation(description: "State update")
        
        menuBarManager.updateState(.scheduling)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.menuBarManager.currentState, .scheduling)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMenuBarTitleUpdates() {
        let testTitle = "2h 30m"
        
        menuBarManager.updateMenuBarTitle(testTitle)
        
        // Allow time for async update
        let expectation = XCTestExpectation(description: "Title update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let button = self.menuBarManager.statusItem?.button {
                XCTAssertEqual(button.attributedTitle?.string, testTitle)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testEmptyTitleShowsIcon() {
        menuBarManager.updateMenuBarTitle("")
        
        let expectation = XCTestExpectation(description: "Icon update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let button = self.menuBarManager.statusItem?.button {
                XCTAssertNotNil(button.image)
                XCTAssertTrue(button.title.isEmpty)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCallbacksAreSet() {
        var scheduleCallbackCalled = false
        var cancelCallbackCalled = false
        
        menuBarManager.onSchedule = { _ in
            scheduleCallbackCalled = true
        }
        
        menuBarManager.onCancel = {
            cancelCallbackCalled = true
        }
        
        // Simulate callbacks
        menuBarManager.onSchedule?(Date())
        menuBarManager.onCancel?()
        
        XCTAssertTrue(scheduleCallbackCalled)
        XCTAssertTrue(cancelCallbackCalled)
    }
}