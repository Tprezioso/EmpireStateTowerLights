//
//  EmpireStateTowerWidget.swift
//  EmpireStateTowerWidget
//
//  Created by Thomas Prezioso Jr on 9/11/23.
//

import DesignSystem
import Models
import SwiftUI
import TowerWidgetKit
import WidgetKit

struct EmpireStateTowerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TowerEntry

    var body: some View {
        switch family {
        case .systemMedium:
            medium.widgetURL(URL(string: "towerlights://tonight"))
        case .systemSmall:
            small.widgetURL(URL(string: "towerlights://tonight"))
        default:
            TowerAccessoryView(entry: entry)
        }
    }

    private var colors: [LightColor] { entry.colors }

    private var small: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 5) {
                Text("Tonight").eyebrowStyle()
                Text(entry.title)
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                ColorSwatchRow(colors: colors, size: 8)
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    sky
                    GlowingTowerView(colors: colors.map(\.color), animatesGlow: false)
                        .padding(.vertical, 8)
                        .offset(x: 40)
                }
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            GlowingTowerView(colors: colors.map(\.color), animatesGlow: false)
                .padding(.vertical, 10)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.lighting.map { "Tonight · \($0.day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))" } ?? "Tonight")
                    .eyebrowStyle()
                Text(entry.title)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if let subtitle = entry.lighting?.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(3)
                } else if entry.lighting == nil {
                    Text("Open the app to check tonight's lights.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                ColorSwatchRow(colors: colors, size: 10)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .containerBackground(for: .widget) {
            ZStack {
                sky
                RadialGradient(
                    colors: [colors[0].color.opacity(0.35), .clear],
                    center: UnitPoint(x: 0.15, y: 0.2),
                    startRadius: 0,
                    endRadius: 160
                )
            }
        }
    }

    private var sky: some View {
        LinearGradient(colors: [Theme.skyTop, Theme.skyMiddle, Theme.skyBottom], startPoint: .top, endPoint: .bottom)
    }
}

struct EmpireStateTowerWidget: Widget {
    let kind = "EmpireStateTowerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TowerTimelineProvider()) { entry in
            EmpireStateTowerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tonight's Tower Lights")
        .description("See what color the Empire State Building is lit tonight.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    EmpireStateTowerWidget()
} timeline: {
    TowerEntry.preview
    TowerEntry(date: .now, lighting: TowerLighting.previewMonth[0])
}

#Preview(as: .systemMedium) {
    EmpireStateTowerWidget()
} timeline: {
    TowerEntry.preview
    TowerEntry(date: .now, lighting: nil)
}

#Preview(as: .accessoryRectangular) {
    EmpireStateTowerWidget()
} timeline: {
    TowerEntry.preview
}
