//
// Created by Berkecan Özgür on 1.12.2022.
//

import Foundation

class MyAPIFunctions
{
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy HH:mm"

        formatter.timeZone = TimeZone(secondsFromGMT: 3*60*60)
        formatter.locale = Locale.current

        return formatter
    }()

    class func shortString(fromDate date: Date) -> String {
        return formatter.string(from: date)
    }

    class func date(fromShortString string: String) -> Date? {
        return formatter.date(from: string)
    }
}