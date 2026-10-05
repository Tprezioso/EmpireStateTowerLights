//
//  LightColor.swift
//  EmpireStateTowerLights
//

import Foundation

/// A color named in a lighting's title.
public enum LightColor: String, CaseIterable, Hashable, Sendable, Codable {
    case red, orange, yellow, gold, green, teal, blue, purple, pink, white, silver

    private static let keywords: [String: [LightColor]] = [
        "red": [.red], "crimson": [.red], "scarlet": [.red], "maroon": [.red],
        "orange": [.orange], "amber": [.orange],
        "yellow": [.yellow],
        "gold": [.gold], "golden": [.gold],
        "green": [.green], "emerald": [.green], "lime": [.green],
        "teal": [.teal], "turquoise": [.teal], "aqua": [.teal], "cyan": [.teal],
        "blue": [.blue], "navy": [.blue], "azure": [.blue],
        "purple": [.purple], "violet": [.purple], "lavender": [.purple], "lilac": [.purple],
        "pink": [.pink], "magenta": [.pink], "fuchsia": [.pink],
        "white": [.white],
        "silver": [.silver],
        "rainbow": [.red, .orange, .yellow, .green, .blue, .purple],
    ]

    /// Extracts colors from a lighting title in the order they're mentioned.
    /// Falls back to `[.white]` (the building's signature white) when no color is named.
    public static func parse(_ title: String) -> [LightColor] {
        var result: [LightColor] = []
        let words = title.lowercased().split { !$0.isLetter }
        for word in words {
            for color in keywords[String(word)] ?? [] where !result.contains(color) {
                result.append(color)
            }
        }
        return result.isEmpty ? [.white] : result
    }
}
