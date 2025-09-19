//
// Created by Berkecan Özgür on 17.09.2025.
//

import Foundation

class DateUtilities {
    // Formatter for pmset command (MM/dd/yy HH:mm:00 - always set seconds to 00)
    static let pmsetFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy HH:mm:00"
        formatter.timeZone = TimeZone.current // Use local timezone
        formatter.locale = Locale.current
        return formatter
    }()
    
    // Formatter for display purposes
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy 'at' HH:mm"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter
    }()
    
    // Format date for pmset command (round to nearest minute)
    class func formatForPmset(date: Date) -> String {
        // Round to the exact minute (remove seconds)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let roundedDate = calendar.date(from: components) ?? date
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy HH:mm:ss"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        
        return formatter.string(from: roundedDate)
    }
    
    // Format date for display
    class func formatForDisplay(date: Date) -> String {
        return displayFormatter.string(from: date)
    }
    
    // Validate that the date is in the future
    class func isValidFutureDate(_ date: Date) -> Bool {
        return date > Date.now
    }
    
    // Get minimum selectable date (current time + 1 minute)
    class func minimumSelectableDate() -> Date {
        return Calendar.current.date(byAdding: .minute, value: 1, to: Date.now) ?? Date.now
    }
    
    // Validate and get error message if invalid
    class func validateScheduleDate(_ date: Date) -> String? {
        if !isValidFutureDate(date) {
            return "Please select a future date and time"
        }
        
        // Check if it's too far in the future (more than 1 year)
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date.now) ?? Date.now
        if date > oneYearFromNow {
            return "Please select a date within the next year"
        }
        
        return nil
    }
}