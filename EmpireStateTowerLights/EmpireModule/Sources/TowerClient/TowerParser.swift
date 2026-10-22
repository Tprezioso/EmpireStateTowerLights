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
    ///
    /// The page is a Next.js app whose rendered markup uses hashed class names, so this reads
    /// the `days` schedule (roughly three months around today) embedded in its flight payload.
    public static func parseCurrent(html: String, baseURL: URL, today: CalendarDay) throws -> CurrentLights {
        do {
            let document = try SwiftSoup.parse(html, baseURL.absoluteString)
            let payload = try document.select("script").array().compactMap { flightChunk(from: $0.data()) }.joined()
            guard let daysJSON = jsonContainer(named: "days", in: payload) else { throw TowerError.parsing }
            // The site fills in a generic description for its default lighting, e.g. Signature White.
            let defaults = jsonContainer(named: "heroTowerLights", in: payload)
                .flatMap { try? JSONDecoder().decode(HeroDefaults.self, from: Data($0.utf8)) }

            var lightings: [CalendarDay: TowerLighting] = [:]
            for scheduled in try JSONDecoder().decode([ScheduledDay].self, from: Data(daysJSON.utf8)) {
                guard let day = CalendarDay(iso: scheduled.date) else { continue }
                let title = normalizeTitle(scheduled.title)
                guard !title.isEmpty else { continue }
                var subtitle = nonEmpty(scheduled.description ?? "")
                if subtitle == nil, let defaults, title.caseInsensitiveCompare(defaults.defaultTitle) == .orderedSame {
                    subtitle = nonEmpty(defaults.defaultDescription)
                }
                lightings[day] = TowerLighting(
                    id: day.iso,
                    day: day,
                    title: title,
                    subtitle: subtitle,
                    imageURL: resolve(scheduled.imageSrc ?? "", baseURL: baseURL)
                )
            }

            guard let todayLighting = lightings[today] else { throw TowerError.parsing }
            return CurrentLights(
                yesterday: lightings[today.adding(days: -1)],
                today: todayLighting,
                tomorrow: lightings[today.adding(days: 1)]
            )
        } catch let error as TowerError {
            throw error
        } catch {
            throw TowerError.parsing
        }
    }

    /// One entry of the tower lights page's `days` schedule.
    private struct ScheduledDay: Decodable {
        var date: String
        var title: String
        var description: String?
        var imageSrc: String?
    }

    /// The tower lights hero's copy for nights without a special lighting.
    private struct HeroDefaults: Decodable {
        var defaultTitle: String
        var defaultDescription: String
    }

    /// `self.__next_f.push([1,"…"])` → the pushed string. Next.js splits its payload across many of these.
    static func flightChunk(from script: String) -> String? {
        let script = script.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = "self.__next_f.push("
        guard script.hasPrefix(prefix), script.hasSuffix(")") else { return nil }
        let arguments = Data(script.dropFirst(prefix.count).dropLast().utf8)
        guard let array = try? JSONSerialization.jsonObject(with: arguments) as? [Any], array.count > 1 else { return nil }
        return array[1] as? String
    }

    /// The JSON text of the first `"name":[…]` array or `"name":{…}` object in `text`, matching brackets outside of strings.
    static func jsonContainer(named name: String, in text: String) -> String? {
        guard let key = text.range(of: "\"\(name)\":[") ?? text.range(of: "\"\(name)\":{") else { return nil }
        let start = text.index(before: key.upperBound)
        var depth = 0
        var inString = false
        var isEscaped = false
        for index in text[start...].indices {
            let character = text[index]
            if inString {
                if isEscaped { isEscaped = false }
                else if character == "\\" { isEscaped = true }
                else if character == "\"" { inString = false }
                continue
            }
            switch character {
            case "\"": inString = true
            case "[", "{": depth += 1
            case "]", "}":
                depth -= 1
                if depth == 0 { return String(text[start...index]) }
            default: break
            }
        }
        return nil
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
