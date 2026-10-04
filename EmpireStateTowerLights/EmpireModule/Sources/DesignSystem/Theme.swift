//
//  Theme.swift
//  EmpireStateTowerLights
//

import Models
import SwiftUI

public enum Theme {
    public static let skyTop = Color(red: 0.043, green: 0.063, blue: 0.149)      // #0B1026
    public static let skyMiddle = Color(red: 0.106, green: 0.078, blue: 0.275)   // #1B1446
    public static let skyBottom = Color(red: 0.020, green: 0.024, blue: 0.051)   // #05060D
    public static let gold = Color(red: 0.910, green: 0.761, blue: 0.478)        // #E8C27A
    public static let towerBody = Color(red: 0.090, green: 0.098, blue: 0.180)
    public static let towerEdge = Color(red: 0.200, green: 0.200, blue: 0.330)
    public static let window = Color(red: 1.0, green: 0.85, blue: 0.55)

    public static let cardCornerRadius: CGFloat = 24
}

extension Font {
    /// Large serif display type for lighting names.
    public static func display(_ style: Font.TextStyle = .largeTitle) -> Font {
        .system(style, design: .serif, weight: .semibold)
    }

    /// Small tracked caps for eyebrow labels like "TONIGHT".
    public static let eyebrow = Font.system(.caption, design: .rounded, weight: .bold)
}

extension LightColor {
    public var color: Color {
        switch self {
        case .red: Color(red: 1.00, green: 0.23, blue: 0.31)
        case .orange: Color(red: 1.00, green: 0.54, blue: 0.16)
        case .yellow: Color(red: 1.00, green: 0.88, blue: 0.35)
        case .gold: Color(red: 0.96, green: 0.77, blue: 0.32)
        case .green: Color(red: 0.20, green: 0.83, blue: 0.60)
        case .teal: Color(red: 0.18, green: 0.83, blue: 0.75)
        case .blue: Color(red: 0.31, green: 0.55, blue: 1.00)
        case .purple: Color(red: 0.65, green: 0.55, blue: 0.98)
        case .pink: Color(red: 1.00, green: 0.44, blue: 0.71)
        case .white: Color(red: 0.97, green: 0.95, blue: 0.90)
        case .silver: Color(red: 0.79, green: 0.82, blue: 0.86)
        }
    }

    public var name: String { rawValue.capitalized }
}

extension TowerLighting {
    public var swatchColors: [Color] { colors.map(\.color) }
}

extension CalendarDay {
    /// "Tonight", "Last Night", "Tomorrow Night", or a date like "Sat, Oct 3".
    public func relativeName(today: CalendarDay) -> String {
        switch self {
        case today: "Tonight"
        case today.adding(days: -1): "Last Night"
        case today.adding(days: 1): "Tomorrow Night"
        default: formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        }
    }
}

extension View {
    /// Frosted glass card used throughout the app.
    public func glassCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
    }

    /// Hides the iOS 26 scroll edge effect, which draws a visible band over the night sky.
    @ViewBuilder
    public func hidesScrollEdgeEffect() -> some View {
        if #available(iOS 26, watchOS 26, *) {
            self.scrollEdgeEffectHidden()
        } else {
            self
        }
    }

    /// Small uppercase gold label.
    public func eyebrowStyle() -> some View {
        self
            .font(.eyebrow)
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(Theme.gold)
    }
}
