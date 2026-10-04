//
//  CalendarDay.swift
//  EmpireStateTowerLights
//

import Foundation

/// The Empire State Building lights by New York local date, so days are modeled
/// as plain year/month/day values in New York time rather than `Date`s.
public struct CalendarDay: Hashable, Comparable, Sendable, Codable {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static let newYork = TimeZone(identifier: "America/New_York")!

    public static var newYorkCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = newYork
        return calendar
    }

    /// The day `date` falls on in New York.
    public init(_ date: Date) {
        let components = Self.newYorkCalendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: components.year ?? 1970, month: components.month ?? 1, day: components.day ?? 1)
    }

    /// Parses `yyyy-MM-dd`.
    public init?(iso string: String) {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    /// Midnight at the start of this day in New York.
    public var date: Date {
        Self.newYorkCalendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    public func adding(days: Int) -> CalendarDay {
        CalendarDay(Self.newYorkCalendar.date(byAdding: .day, value: days, to: date) ?? date)
    }

    public var yearMonth: YearMonth { YearMonth(year: year, month: month) }

    public var iso: String { String(format: "%04d-%02d-%02d", year, month, day) }

    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// Formats this day, e.g. `.dateTime.weekday(.wide).month().day()`.
    public func formatted(_ format: Date.FormatStyle) -> String {
        var format = format
        format.timeZone = Self.newYork
        return date.formatted(format)
    }
}
