//
//  AppFeature.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/5/23.
//

import AboutFeature
import ComposableArchitecture
import CurrentTowerFeature
import DesignSystem
import Foundation
import MonthlyTowerFeature
import SwiftUI
import TowerClient

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab = .tonight
        public var tonight = CurrentTowerFeature.State()
        public var calendar = MonthlyTowerFeature.State()
        @Presents public var about: AboutFeature.State?

        public init() {}
    }

    public enum Tab: String, Hashable, Sendable {
        case tonight, calendar
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case appLaunched
        case about(PresentationAction<AboutFeature.Action>)
        case tonight(CurrentTowerFeature.Action)
        case calendar(MonthlyTowerFeature.Action)
        case openURL(URL)
        case open(Tab)
    }

    /// The URL scheme used by the widget, e.g. `towerlights://calendar`.
    public static let urlScheme = "towerlights"

    @Dependency(\.tipJar) var tipJar

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.tonight, action: \.tonight) {
            CurrentTowerFeature()
        }
        Scope(state: \.calendar, action: \.calendar) {
            MonthlyTowerFeature()
        }
        Reduce { state, action in
            switch action {
            case .appLaunched:
                // Apple requires finishing any tip transactions delivered outside a purchase flow.
                return .run { _ in await tipJar.finishTransactions() }

            case .tonight(.delegate(.showAbout)):
                state.about = AboutFeature.State()
                return .none

            case .binding, .tonight, .calendar, .about:
                return .none

            case let .openURL(url):
                guard url.scheme == Self.urlScheme, let tab = Tab(rawValue: url.host() ?? "") else {
                    return .none
                }
                return .send(.open(tab))

            case let .open(tab):
                state.selectedTab = tab
                state.about = nil
                state.tonight.detail = nil
                state.calendar.detail = nil
                return .none
            }
        }
        .ifLet(\.$about, action: \.about) {
            AboutFeature()
        }
    }
}

#if os(iOS)
public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        TabView(selection: $store.selectedTab) {
            CurrentTowerView(store: store.scope(state: \.tonight, action: \.tonight))
                .tabItem { Label("Tonight", systemImage: "building.2.fill") }
                .tag(AppFeature.Tab.tonight)

            MonthlyTowerView(store: store.scope(state: \.calendar, action: \.calendar))
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppFeature.Tab.calendar)
        }
        .tint(Theme.gold)
        .preferredColorScheme(.dark)
        .onOpenURL { store.send(.openURL($0)) }
        .sheet(item: $store.scope(state: \.about, action: \.about)) { aboutStore in
            AboutView(store: aboutStore)
        }
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) {
        AppFeature()
    } withDependencies: {
        $0.towerClient = .previewValue
    })
}
#endif
