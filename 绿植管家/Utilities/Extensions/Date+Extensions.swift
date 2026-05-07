//
//  Date+Extensions.swift
//  绿植管家
//

import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
