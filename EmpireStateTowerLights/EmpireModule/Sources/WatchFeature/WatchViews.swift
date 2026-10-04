//
//  WatchViews.swift
//  EmpireStateTowerLights
//

#if os(watchOS)
import ComposableArchitecture
import CurrentTowerFeature
import DesignSystem
import Models
import MonthlyTowerFeature
import SwiftUI

/// Root of the watch app. Owns its store so the app target only needs `import WatchFeature`.
public struct WatchRootView: View {
    @State private var store = Store(initialState: WatchAppFeature.State()) {
        WatchAppFeature()
    }

    public init() {}

    public var body: some View {
        WatchContentView(store: store)
    }
}

struct WatchContentView: View {
    @Bindable var store: StoreOf<WatchAppFeature>

    var body: some View {
        NavigationStack {
            TonightPager(store: store.scope(state: \.tonight, action: \.tonight))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            store.send(.calendarButtonTapped)
                        } label: {
                            Image(systemName: "calendar")
                        }
                        .accessibilityLabel("Lights calendar")
                    }
                }
                .navigationDestination(isPresented: $store.isShowingCalendar) {
                    WatchCalendarView(store: store.scope(state: \.calendar, action: \.calendar))
                }
        }
        .tint(Theme.gold)
    }
}

// MARK: - Tonight

/// Turn the Digital Crown to page Last Night → Tonight → Tomorrow.
struct TonightPager: View {
    @Bindable var store: StoreOf<CurrentTowerFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let lights = store.lights {
                TabView(selection: $store.selectedDay) {
                    ForEach(store.availableDays, id: \.self) { day in
                        if let lighting = lights.lighting(for: day) {
                            Button {
                                store.send(.lightingTapped(lighting))
                            } label: {
                                WatchLightingPage(lighting: lighting, label: day.title)
                            }
                            .buttonStyle(.plain)
                            .tag(day)
                            .containerBackground(lighting.watchBackground, for: .tabView)
                        }
                    }
                }
                .tabViewStyle(.verticalPage)
                .sensoryFeedback(.selection, trigger: store.selectedDay)
            } else if let message = store.errorMessage, !store.isLoading {
                ScrollView {
                    VStack(spacing: 10) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.title2)
                            .foregroundStyle(Theme.gold)
                        Text(message)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                        Button("Try Again") { store.send(.retryButtonTapped) }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    GlowingTowerView(colors: [.white.opacity(0.4)], animatesGlow: false)
                    ProgressView()
                }
            }
        }
        .navigationTitle("Tower Lights")
        .task { store.send(.task) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.sceneBecameActive) }
        }
        .navigationDestination(item: $store.detail) { lighting in
            WatchLightingDetail(lighting: lighting)
        }
    }
}

struct WatchLightingPage: View {
    var lighting: TowerLighting
    var label: String
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            GlowingTowerView(colors: lighting.swatchColors, animatesGlow: !isLuminanceReduced && !reduceMotion)
                .opacity(isLuminanceReduced ? 0.6 : 1)
                .frame(maxHeight: .infinity)
            Text(label).eyebrowStyle()
            Text(lighting.title)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            ColorSwatchRow(colors: lighting.colors, size: 7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(lighting.spokenDescription)")
        .accessibilityHint("Shows details")
    }
}

struct WatchLightingDetail: View {
    var lighting: TowerLighting

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(lighting.day.formatted(.dateTime.weekday(.wide).month().day())).eyebrowStyle()
                Text(lighting.title)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                ColorSwatchRow(colors: lighting.colors, size: 10)
                if let subtitle = lighting.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text("Courtesy of the Empire State Building")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(lighting.watchBackground, for: .navigation)
    }
}

// MARK: - Calendar

struct WatchCalendarView: View {
    @Bindable var store: StoreOf<MonthlyTowerFeature>

    var body: some View {
        List {
            if let lightings = store.lightings {
                if lightings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Signature White")
                            .font(.system(.headline, design: .serif, weight: .semibold))
                        Text("No special lightings scheduled this month.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(lightings) { lighting in
                        Button {
                            store.send(.lightingTapped(lighting))
                        } label: {
                            WatchCalendarRow(lighting: lighting, isToday: lighting.day == store.today)
                        }
                    }
                }
            } else if let message = store.errorMessage, !store.isLoading {
                Text(message).font(.footnote)
                Button("Try Again") { store.send(.retryButtonTapped) }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(store.month?.monthName ?? "Calendar")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    store.send(.previousMonthTapped)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Button {
                    store.send(.nextMonthTapped)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel("Next month")
            }
        }
        .task { store.send(.task) }
        .navigationDestination(item: $store.detail) { lighting in
            WatchLightingDetail(lighting: lighting)
        }
        .containerBackground(Theme.skyMiddle.gradient, for: .navigation)
    }
}

struct WatchCalendarRow: View {
    var lighting: TowerLighting
    var isToday: Bool

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 0) {
                Text(lighting.day.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                Text(lighting.day.formatted(.dateTime.day()))
                    .font(.system(.title3, design: .serif, weight: .semibold))
            }
            .foregroundStyle(isToday ? Theme.gold : .primary)
            .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(lighting.title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(2)
                ColorSwatchRow(colors: lighting.colors, size: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isToday ? "Tonight, " : "")\(lighting.day.formatted(.dateTime.weekday(.wide).month(.wide).day())): \(lighting.spokenDescription)")
    }
}

extension TowerLighting {
    /// The night's first color fading into the night sky.
    var watchBackground: LinearGradient {
        LinearGradient(
            colors: [(colors.first ?? .white).color.opacity(0.45), Theme.skyMiddle, Theme.skyBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
#endif
