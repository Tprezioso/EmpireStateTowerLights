//
//  TowerLighting.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import Foundation

/// One night's lighting on the Empire State Building.
public struct TowerLighting: Equatable, Hashable, Identifiable, Sendable, Codable {
    public var id: String
    public var day: CalendarDay
    /// The name of the lighting, e.g. "Red, White, and Blue".
    public var title: String
    /// What the lighting honors, e.g. "In Celebration of Independence Day".
    public var subtitle: String?
    public var imageURL: URL?

    public init(id: String? = nil, day: CalendarDay, title: String, subtitle: String? = nil, imageURL: URL? = nil) {
        self.id = id ?? "\(day.iso)-\(title)"
        self.day = day
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
    }

    public var colors: [LightColor] { LightColor.parse(title) }

    /// A sentence suitable for VoiceOver and Siri.
    public var spokenDescription: String {
        guard let subtitle, !subtitle.isEmpty else { return title }
        return "\(title), \(subtitle.prefix(1).lowercased() + subtitle.dropFirst())"
    }
}

/// The lightings shown on the ESB home page: yesterday, today and tomorrow.
public struct CurrentLights: Equatable, Hashable, Sendable, Codable {
    public var yesterday: TowerLighting?
    public var today: TowerLighting
    public var tomorrow: TowerLighting?

    public init(yesterday: TowerLighting?, today: TowerLighting, tomorrow: TowerLighting?) {
        self.yesterday = yesterday
        self.today = today
        self.tomorrow = tomorrow
    }
}

extension TowerLighting {
    public static let preview = TowerLighting(
        day: CalendarDay(year: 2026, month: 7, day: 4),
        title: "Red, White, and Blue",
        subtitle: "In Celebration of the Fourth of July",
        imageURL: URL(string: "https://www.esbnyc.com/sites/default/files/styles/260x370/public/2020-01/thumbnail5M2VW4ZF.jpg")
    )

    public static let previewMonth: [TowerLighting] = [
        TowerLighting(day: CalendarDay(year: 2026, month: 10, day: 1), title: "Pink with a Ribbon Rotating in the Mast", subtitle: "In Honor of Breast Cancer Awareness Month"),
        TowerLighting(day: CalendarDay(year: 2026, month: 10, day: 1), title: "Red, White, and Blue", subtitle: "10-11 p.m.: In Honor of the New York Rangers’ Home Opener"),
        TowerLighting(day: CalendarDay(year: 2026, month: 10, day: 3), title: "Blue and Orange", subtitle: "In Honor of the New York Islanders’ Home Opener"),
        TowerLighting(day: CalendarDay(year: 2026, month: 10, day: 31), title: "Orange and Green", subtitle: "In Celebration of Halloween")
    ]
}

extension CurrentLights {
    public static let preview = CurrentLights(
        yesterday: TowerLighting(day: CalendarDay(year: 2026, month: 10, day: 2), title: "Signature White"),
        today: TowerLighting(day: CalendarDay(year: 2026, month: 10, day: 3), title: "Blue and Orange", subtitle: "In Honor of the New York Islanders’ Home Opener"),
        tomorrow: TowerLighting(day: CalendarDay(year: 2026, month: 10, day: 4), title: "Signature White")
    )
}
