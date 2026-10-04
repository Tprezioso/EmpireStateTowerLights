//
//  ShareCard.swift
//  EmpireStateTowerLights
//

import Models
import SwiftUI

/// A square, vector-only card describing a lighting, rendered to an image for sharing.
public struct ShareCardView: View {
    var lighting: TowerLighting
    var today: CalendarDay

    public init(lighting: TowerLighting, today: CalendarDay) {
        self.lighting = lighting
        self.today = today
    }

    public var body: some View {
        HStack(spacing: 24) {
            GlowingTowerView(colors: lighting.swatchColors, animatesGlow: false)
                .frame(height: 300)
            VStack(alignment: .leading, spacing: 12) {
                Text("Empire State Building").eyebrowStyle()
                Text(lighting.day.relativeName(today: today))
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Text(lighting.title)
                    .font(.display(.largeTitle))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                ColorSwatchRow(colors: lighting.colors, size: 20)
                if let subtitle = lighting.subtitle {
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text(lighting.day.formatted(.dateTime.month(.wide).day().year()))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer(minLength: 0)
        }
        .padding(36)
        .frame(width: 600, height: 400)
        .background {
            LinearGradient(colors: [Theme.skyTop, Theme.skyMiddle, Theme.skyBottom], startPoint: .top, endPoint: .bottom)
        }
        .environment(\.colorScheme, .dark)
    }
}

/// Renders a ``ShareCardView`` and shares it.
public struct ShareLightingButton: View {
    var lighting: TowerLighting
    var today: CalendarDay
    @State private var image: Image?
    @Environment(\.displayScale) private var displayScale

    public init(lighting: TowerLighting, today: CalendarDay) {
        self.lighting = lighting
        self.today = today
    }

    private var message: String {
        "The Empire State Building is lit \(lighting.title) \(lighting.day.relativeName(today: today).lowercased())."
    }

    public var body: some View {
        Group {
            if let image {
                ShareLink(item: image, message: Text(message), preview: SharePreview(lighting.title, image: image)) {
                    label
                }
            } else {
                ShareLink(item: message) { label }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.gold)
        .foregroundStyle(Theme.skyBottom)
        .task(id: lighting) { render() }
    }

    private var label: some View {
        Label("Share", systemImage: "square.and.arrow.up")
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: ShareCardView(lighting: lighting, today: today))
        renderer.scale = displayScale
        if let uiImage = renderer.uiImage {
            image = Image(uiImage: uiImage)
        }
    }
}

#Preview {
    ShareCardView(lighting: .preview, today: TowerLighting.preview.day)
}
