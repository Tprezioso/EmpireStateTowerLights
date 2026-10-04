//
//  YearMonth.swift
//  EmpireStateTowerLights
//

import Foundation

public struct YearMonth: Hashable, Comparable, Sendable, Codable {
    public var year: Int
    public var month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public init(_ date: Date) {
        self = CalendarDay(date).yearMonth
    }

    /// The path component the ESB calendar uses, e.g. `202610`.
    public var pathComponent: String { String(format: "%04d%02d", year, month) }

    public var next: YearMonth { adding(months: 1) }
    public var previous: YearMonth { adding(months: -1) }

    public func adding(months: Int) -> YearMonth {
        let index = year * 12 + (month - 1) + months
        return YearMonth(year: index / 12, month: index % 12 + 1)
    }

    /// e.g. "October 2026".
    public var title: String {
        CalendarDay(year: year, month: month, day: 1).formatted(.dateTime.month(.wide).year())
    }

    /// e.g. "October".
    public var monthName: String {
        CalendarDay(year: year, month: month, day: 1).formatted(.dateTime.month(.wide))
    }

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}
