//
//  TowerWidgetKit.swift
//  EmpireStateTowerLights
//
//  Shared by the iPhone widget and the Apple Watch complications.
//

import DesignSystem
import Models
import SwiftUI
import TowerClient
import WidgetKit
#if canImport(UIKit)
import UIKit
#endif

public struct TowerEntry: TimelineEntry {
    public var date: Date
    /// `nil` when the lights couldn't be loaded.
    public var lighting: TowerLighting?
    #if os(iOS)
    public var image: UIImage?
    #endif
    public var relevance: TimelineEntryRelevance?

    public init(date: Date, lighting: TowerLighting?) {
        self.date = date
        self.lighting = lighting
        self.relevance = TimelineEntryRelevance(score: Self.isEvening(date) ? 80 : 20)
    }

    public static let preview = TowerEntry(date: .now, lighting: CurrentLights.preview.today)

    public var title: String { lighting?.title ?? "Tower Lights" }
    public var colors: [LightColor] { lighting?.colors ?? [.white] }

    /// The lights are on from dusk; rank the widget higher in the Smart Stack from 6 pm to 2 am New York time.
    static func isEvening(_ date: Date) -> Bool {
        let hour = CalendarDay.newYorkCalendar.component(.hour, from: date)
        return hour >= 18 || hour < 2
    }
}

public struct TowerTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> TowerEntry {
        .preview
    }

    public func getSnapshot(in context: Context, completion: @escaping (TowerEntry) -> Void) {
        guard !context.isPreview else {
            completion(.preview)
            return
        }
        Task {
            completion(await fetchEntry(family: context.family) ?? .preview)
        }
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<TowerEntry>) -> Void) {
        Task {
            guard let entry = await fetchEntry(family: context.family) else {
                let retry = Date.now.addingTimeInterval(30 * 60)
                completion(Timeline(entries: [TowerEntry(date: .now, lighting: nil)], policy: .after(retry)))
                return
            }
            let refresh = Self.nextRefresh(after: entry.date)
            var entries = [entry]
            // Re-rank for the Smart Stack when the evening starts.
            let evening = CalendarDay(entry.date).date.addingTimeInterval(18 * 60 * 60)
            if evening > entry.date, evening < refresh {
                var eveningEntry = entry
                eveningEntry.date = evening
                eveningEntry.relevance = TimelineEntryRelevance(score: 80)
                entries.append(eveningEntry)
            }
            completion(Timeline(entries: entries, policy: .after(refresh)))
        }
    }

    private func fetchEntry(family: WidgetFamily) async -> TowerEntry? {
        guard let lighting = try? await TowerClient.liveValue.current().today else { return nil }
        var entry = TowerEntry(date: .now, lighting: lighting)
        #if os(iOS)
        if family == .systemSmall, let url = lighting.imageURL,
           let (data, _) = try? await URLSession.shared.data(from: url) {
            // Keep well under the widget memory limit.
            entry.image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 400, height: 400))
        }
        #endif
        return entry
    }

    /// Shortly after midnight in New York (when the lights change), or within six hours
    /// so late schedule announcements are picked up.
    public static func nextRefresh(after date: Date) -> Date {
        let tomorrow = CalendarDay(date).adding(days: 1).date.addingTimeInterval(5 * 60)
        return min(tomorrow, date.addingTimeInterval(6 * 60 * 60))
    }
}

/// Lock Screen and watch face layouts.
public struct TowerAccessoryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TowerEntry

    public init(entry: TowerEntry) {
        self.entry = entry
    }

    public var body: some View {
        content
            .containerBackground(for: .widget) { Color.clear }
            .widgetURL(URL(string: "towerlights://tonight"))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            Label(entry.lighting.map { "ESB: \($0.title)" } ?? "ESB Tower Lights", systemImage: "building.2.fill")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                ColorRing(colors: entry.colors.map(\.color))
                    .padding(4)
                Image(systemName: "building.2.fill")
                    .font(.title3)
            }
            .widgetAccentable()
        #if os(watchOS)
        case .accessoryCorner:
            Image(systemName: "building.2.fill")
                .font(.title3)
                .widgetAccentable()
                .widgetLabel {
                    Text(entry.title)
                }
        #endif
        default:
            rectangular
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("ESB Tonight", systemImage: "building.2.fill")
                .font(.caption2.weight(.semibold))
                .widgetAccentable()
            Text(entry.title)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            #if os(watchOS)
            ColorSwatchRow(colors: entry.colors, size: 7)
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A ring split into one arc per color.
public struct ColorRing: View {
    var colors: [Color]

    public init(colors: [Color]) {
        self.colors = colors
    }

    public var body: some View {
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
