//
//  WatchWidgets.swift
//  EmpireStateTowerWatchWidgets
//

import Models
import SwiftUI
import TowerWidgetKit
import WidgetKit

@main
struct TowerLightsComplication: Widget {
    let kind = "TowerLightsComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TowerTimelineProvider()) { entry in
            TowerAccessoryView(entry: entry)
        }
        .configurationDisplayName("Tonight's Tower Lights")
        .description("What color the Empire State Building is lit tonight.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

#Preview(as: .accessoryRectangular) {
    TowerLightsComplication()
} timeline: {
    TowerEntry.preview
    TowerEntry(date: .now, lighting: TowerLighting.previewMonth[0])
}

#Preview(as: .accessoryCorner) {
    TowerLightsComplication()
} timeline: {
    TowerEntry.preview
}
