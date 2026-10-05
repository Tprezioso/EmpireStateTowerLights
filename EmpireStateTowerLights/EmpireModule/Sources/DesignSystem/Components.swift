//
//  Components.swift
//  EmpireStateTowerLights
//

import Models
import SwiftUI

/// A row of glowing color dots for a lighting.
public struct ColorSwatchRow: View {
    var colors: [LightColor]
    var size: CGFloat

    public init(colors: [LightColor], size: CGFloat = 14) {
        self.colors = colors
        self.size = size
    }

    public var body: some View {
        HStack(spacing: size * 0.5) {
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: size, height: size)
                    .shadow(color: color.color.opacity(0.8), radius: size * 0.4)
                    .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.5))
            }
        }
        .accessibilityElement()
        .accessibilityLabel(colors.map(\.name).formatted(.list(type: .and)))
    }
}

/// The ESB's own photo of a lighting, with a graceful placeholder.
public struct TowerPhoto: View {
    var url: URL?
    var colors: [Color]

    public init(url: URL?, colors: [Color]) {
        self.url = url
        self.colors = colors
    }

    public var body: some View {
        // A filled image reports its natural size, so a wide photo would widen the
        // surrounding layout. Size with a flexible clear view and draw the photo in an
        // overlay, which never affects layout.
        Color.clear
            .overlay {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.3))) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        ZStack {
                            LinearGradient(colors: [Theme.skyMiddle, Theme.skyBottom], startPoint: .top, endPoint: .bottom)
                            GlowingTowerView(colors: colors, animatesGlow: false)
                                .padding(12)
                                .opacity(phase.error == nil && url != nil ? 0.4 : 1)
                        }
                    @unknown default:
                        Color.clear
                    }
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

/// Inline error with a retry button. Replaces the old repeated alerts.
public struct ErrorCard: View {
    var message: String
    var retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Lights out", systemImage: "wifi.exclamationmark")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(action: retry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.gold)
            .foregroundStyle(Theme.skyBottom)
        }
        .glassCard()
    }
}

/// A list row for the calendar timeline.
public struct LightingRow: View {
    var lighting: TowerLighting
    var isToday: Bool

    public init(lighting: TowerLighting, isToday: Bool) {
        self.lighting = lighting
        self.isToday = isToday
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(spacing: 2) {
                Text(lighting.day.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(isToday ? Theme.gold : .secondary)
                Text(lighting.day.formatted(.dateTime.day()))
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(isToday ? Theme.gold : .primary)
            }
            .frame(width: 44)

            TowerPhoto(url: lighting.imageURL, colors: lighting.swatchColors)
                .frame(width: 52, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                if isToday {
                    Text("Tonight").eyebrowStyle()
                }
                Text(lighting.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                if let subtitle = lighting.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                ColorSwatchRow(colors: lighting.colors, size: 10)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(isToday ? Theme.gold.opacity(0.7) : .white.opacity(0.1), lineWidth: isToday ? 1.5 : 1)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isToday ? "Tonight, " : "")\(lighting.day.formatted(.dateTime.weekday(.wide).month(.wide).day())): \(lighting.spokenDescription)")
        .accessibilityAddTraits(.isButton)
    }
}

/// Shimmering skeleton shown while loading.
public struct LoadingCard: View {
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule().frame(width: 80, height: 10)
            Capsule().frame(width: 220, height: 26)
            Capsule().frame(width: 160, height: 12)
        }
        .foregroundStyle(.white.opacity(isAnimating ? 0.18 : 0.08))
        .glassCard()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever()) { isAnimating = true }
        }
        .accessibilityElement()
        .accessibilityLabel("Loading tower lights")
    }
}

/// Attribution for ESB photos and schedule data.
public struct PhotoCredit: View {
    public init() {}

    public var body: some View {
        Text("Photo: Empire State Building")
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.45), in: Capsule())
    }
}

/// Footer crediting the Empire State Building as the source of the schedule and photos.
public struct SourceCredit: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 4) {
            Text("Schedule and photos courtesy of the Empire State Building.")
            Link("esbnyc.com", destination: URL(string: "https://www.esbnyc.com/about/tower-lights")!)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.gold)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
