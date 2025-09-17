//
//  SleepSchedulerService.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import Foundation
import Cocoa

enum SchedulingState {
    case idle
    case scheduling
    case success(String)
    case error(String)
}

class SleepSchedulerService: ObservableObject {
    @Published var state: SchedulingState = .idle
    
    func scheduleSleep(for date: Date) {
        // Validate the date first
        if let validationError = DateUtilities.validateScheduleDate(date) {
            state = .error(validationError)
            return
        }
        
        state = .scheduling
        
        // Format the date for pmset command
        let formattedDate = DateUtilities.formatForPmset(date: date)
        let displayDate = DateUtilities.formatForDisplay(date: date)
        
        // Create the pmset command
        let command = "pmset schedule sleep '\(formattedDate)'"
        let nsScriptCommand = "do shell script \"\(command)\" with administrator privileges"
        
        // Execute the command
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var error: NSDictionary?
            let scriptObject = NSAppleScript(source: nsScriptCommand)
            let _ = scriptObject?.executeAndReturnError(&error)
            
            DispatchQueue.main.async {
                if let errorDict = error {
                    let errorMessage = self?.parseAppleScriptError(errorDict) ?? "Unknown error occurred"
                    self?.state = .error(errorMessage)
                } else {
                    self?.state = .success("Sleep scheduled successfully for \(displayDate)")
                }
            }
        }
    }
    
    private func parseAppleScriptError(_ errorDict: NSDictionary) -> String {
        if let errorMessage = errorDict["NSAppleScriptErrorMessage"] as? String {
            if errorMessage.contains("User canceled") {
                return "Administrator authentication was cancelled"
            } else if errorMessage.contains("pmset") {
                return "Failed to set sleep schedule. Please check system permissions."
            } else {
                return "Error: \(errorMessage)"
            }
        }
        return "An unknown error occurred while scheduling sleep"
    }
    
    func resetState() {
        state = .idle
    }
}