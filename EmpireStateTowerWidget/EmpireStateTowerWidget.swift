//
//  EmpireStateTowerWidget.swift
//  EmpireStateTowerWidget
//
//  Created by Thomas Prezioso Jr on 9/11/23.
//

import DesignSystem
import Models
import SwiftUI
import TowerClient
import UIKit
import WidgetKit

struct TowerEntry: TimelineEntry {
    var date: Date
    /// `nil` when the lights couldn't be loaded.
    var lighting: TowerLighting?
    var image: UIImage?

    static let preview = TowerEntry(date: .now, lighting: CurrentLights.preview.today)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TowerEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (TowerEntry) -> Void) {
        guard !context.isPreview else {
            completion(.preview)
            return
        }
        Task {
            completion(await fetchEntry(family: context.family) ?? .preview)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TowerEntry>) -> Void) {
        Task {
            if let entry = await fetchEntry(family: context.family) {
                completion(Timeline(entries: [entry], policy: .after(Self.nextRefresh(after: entry.date))))
            } else {
                let retry = Date.now.addingTimeInterval(30 * 60)
                completion(Timeline(entries: [TowerEntry(date: .now, lighting: nil)], policy: .after(retry)))
            }
        }
    }

    private func fetchEntry(family: WidgetFamily) async -> TowerEntry? {
        guard let lighting = try? await TowerClient.liveValue.current().today else { return nil }
        var image: UIImage?
        if family == .systemSmall, let url = lighting.imageURL,
           let (data, _) = try? await URLSession.shared.data(from: url) {
            // Keep well under the widget memory limit.
            image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 400, height: 400))
        }
        return TowerEntry(date: .now, lighting: lighting, image: image)
    }

    /// Shortly after midnight in New York (when the lights change), or within six hours
    /// so late schedule announcements are picked up.
    static func nextRefresh(after date: Date) -> Date {
        let tomorrow = CalendarDay(date).adding(days: 1).date.addingTimeInterval(5 * 60)
        return min(tomorrow, date.addingTimeInterval(6 * 60 * 60))
    }
}

struct EmpireStateTowerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TowerEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                inline
            case .accessoryCircular:
                circular
            case .accessoryRectangular:
                rectangular
            case .systemMedium:
                medium
            default:
                small
            }
        }
        .widgetURL(URL(string: "towerlights://tonight"))
    }

    private var title: String { entry.lighting?.title ?? "Tower Lights" }
    private var colors: [LightColor] { entry.lighting?.colors ?? [.white] }

    // MARK: Home Screen

    private var small: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 5) {
                Text("Tonight").eyebrowStyle()
                Text(title)
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
                Text(title)
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

    // MARK: Lock Screen

    private var inline: some View {
        Label(entry.lighting.map { "ESB: \($0.title)" } ?? "ESB Tower Lights", systemImage: "building.2.fill")
            .containerBackground(for: .widget) { Color.clear }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            ColorRing(colors: colors.map(\.color))
                .padding(4)
            Image(systemName: "building.2.fill")
                .font(.title3)
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { Color.clear }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("ESB Tonight", systemImage: "building.2.fill")
                .font(.caption2.weight(.semibold))
                .widgetAccentable()
            Text(title)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }
}

/// A ring split into one arc per color.
private struct ColorRing: View {
    var colors: [Color]

    var body: some View {
        ZStack {
            ForEach(colors.indices, id: \.self) { index in
                Circle()
                    .trim(
                        from: CGFloat(index) / CGFloat(colors.count) + 0.01,
                        to: CGFloat(index + 1) / CGFloat(colors.count) - 0.01
                    )
                    .stroke(colors[index], style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

struct EmpireStateTowerWidget: Widget {
    let kind = "EmpireStateTowerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
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
