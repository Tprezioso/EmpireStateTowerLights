//
//  TowerParser.swift
//  EmpireStateTowerLights
//

import Foundation
import Models
import SwiftSoup

/// Turns esbnyc.com HTML into ``TowerLighting`` values.
public enum TowerParser {
    /// Parses https://www.esbnyc.com/about/tower-lights
    public static func parseCurrent(html: String, baseURL: URL, fallbackToday: CalendarDay) throws -> CurrentLights {
        do {
            let document = try SwiftSoup.parse(html, baseURL.absoluteString)
            guard let todayElement = try document.getElementsByClass("is-today").first() else {
                throw TowerError.parsing
            }

            let today = try parseDay(from: todayElement.select("h2").text()) ?? fallbackToday
            let todayTitle = normalizeTitle(try todayElement.select("h3").text())
            guard !todayTitle.isEmpty else { throw TowerError.parsing }

            let backgroundStyle = try document.getElementsByClass("background-image-wrapper").first()?.attr("style") ?? ""
            let todayLighting = TowerLighting(
                id: "today-\(today.iso)",
                day: today,
                title: todayTitle,
                subtitle: nonEmpty(try todayElement.select("p").text()),
                imageURL: backgroundImageURL(from: backgroundStyle, baseURL: baseURL)
            )

            var yesterday: TowerLighting?
            var tomorrow: TowerLighting?
            for (index, element) in try document.getElementsByClass("not-today").array().enumerated() {
                let heading = try element.select("h2").text().lowercased()
                let isYesterday = heading.contains("yesterday") || (!heading.contains("tomorrow") && index == 0)
                let day = today.adding(days: isYesterday ? -1 : 1)
                let title = normalizeTitle(try element.select("h3").text())
                guard !title.isEmpty else { continue }
                let lighting = TowerLighting(
                    id: "\(isYesterday ? "yesterday" : "tomorrow")-\(day.iso)",
                    day: day,
                    title: title,
                    subtitle: nonEmpty(try element.select("p").text()),
                    imageURL: resolve(try element.select("img").attr("src"), baseURL: baseURL)
                )
                if isYesterday { yesterday = lighting } else { tomorrow = lighting }
            }

            return CurrentLights(yesterday: yesterday, today: todayLighting, tomorrow: tomorrow)
        } catch let error as TowerError {
            throw error
        } catch {
            throw TowerError.parsing
        }
    }

    /// Parses https://www.esbnyc.com/about/tower-lights/calendar/YYYYMM
    public static func parseMonth(html: String, baseURL: URL) throws -> [TowerLighting] {
        do {
            let document = try SwiftSoup.parse(html, baseURL.absoluteString)
            guard try !document.getElementsByClass("lights-calendar-view").isEmpty() else {
                throw TowerError.parsing
            }
            return try document.select("article.lse").array().enumerated().compactMap { index, article in
                guard
                    let day = CalendarDay(iso: try article.attr("data-date")),
                    case let title = normalizeTitle(try article.getElementsByClass("name").text()),
                    !title.isEmpty
                else { return nil }
                return TowerLighting(
                    id: "\(day.iso)-\(index)",
                    day: day,
                    title: title,
                    subtitle: nonEmpty(try article.getElementsByClass("field_description").text()),
                    imageURL: resolve(try article.select("img[src]").first()?.attr("src") ?? "", baseURL: baseURL)
                )
            }
        } catch let error as TowerError {
            throw error
        } catch {
            throw TowerError.parsing
        }
    }

    /// "Blue and Orange COLOR" → "Blue and Orange", "SIGNATURE WHITE" → "Signature White".
    static func normalizeTitle(_ raw: String) -> String {
        var title = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.lowercased().hasSuffix(" color") {
            title = String(title.dropLast(" color".count)).trimmingCharacters(in: .whitespaces)
        }
        if title == title.uppercased() {
            title = title.capitalized
        }
        return title
    }

    /// "Today, October 03, 2026" → 2026-10-03.
    static func parseDay(from heading: String) -> CalendarDay? {
        let pattern = #/([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})/#
        guard let match = heading.firstMatch(of: pattern),
              let day = Int(match.2), let year = Int(match.3)
        else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let month = formatter.monthSymbols.firstIndex(where: { $0.caseInsensitiveCompare(String(match.1)) == .orderedSame })
        else { return nil }
        return CalendarDay(year: year, month: month + 1, day: day)
    }

    /// `background-image:url(/sites/…/image.jpg)` → absolute URL.
    static func backgroundImageURL(from style: String, baseURL: URL) -> URL? {
        guard let start = style.range(of: "url("), let end = style.range(of: ")", range: start.upperBound..<style.endIndex)
        else { return nil }
        let path = style[start.upperBound..<end.lowerBound].trimmingCharacters(in: CharacterSet(charactersIn: "'\" "))
        return resolve(path, baseURL: baseURL)
    }

    static func resolve(_ path: String, baseURL: URL) -> URL? {
        let path = path.trimmingCharacters(in: .whitespaces)
        guard !path.isEmpty else { return nil }
        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }

    private static func nonEmpty(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
