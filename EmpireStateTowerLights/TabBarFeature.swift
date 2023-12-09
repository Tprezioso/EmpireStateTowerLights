//
//  TabBarFeature.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/5/23.
//

import ComposableArchitecture
import SwiftUI
import CurrentTowerFeature
import MonthlyTowerFeature

struct TabBarFeature: Reducer {
    struct State: Equatable {
        init(currentTowerTab: CurrentTowerLightsFeature.State = CurrentTowerLightsFeature.State(), monthlyTowerTab: MonthlyTowerLightsFeature.State = MonthlyTowerLightsFeature.State(), selectedTab: Tab = .current) {
            self.currentTowerTab = currentTowerTab
            self.monthlyTowerTab = monthlyTowerTab
            self.selectedTab = selectedTab
        }
        
        var currentTowerTab = CurrentTowerLightsFeature.State()
        var monthlyTowerTab = MonthlyTowerLightsFeature.State()
        var selectedTab: Tab = .current
    }

    enum Action: Equatable {
        case currentTowerTab(CurrentTowerLightsFeature.Action)
        case monthlyTowerTab(MonthlyTowerLightsFeature.Action)
        case selectedTabChanged(Tab)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {                
            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none

            case .currentTowerTab, .monthlyTowerTab:
                return .none
            }
        }

        Scope(state: \.currentTowerTab, action: /Action.currentTowerTab) {
            CurrentTowerLightsFeature()
        }
        Scope(state: \.monthlyTowerTab, action: /Action.monthlyTowerTab) {
            MonthlyTowerLightsFeature()
        }
    }
}

enum Tab {
    case current, monthly
}

struct TabBarView: View {

    @StateObject var viewModel = ViewModel.shared

    class ViewModel: ObservableObject {
        init() {
            self.store = Store(initialState: .init()) {
                TabBarFeature()
            }
        }
        static var shared = ViewModel()
        let store: StoreOf<TabBarFeature>
    }

    var body: some View {
        WithViewStore(viewModel.store, observe: \.selectedTab) { viewStore in
            TabView(selection: viewStore.binding(send: TabBarFeature.Action.selectedTabChanged)) {
                CurrentTowerLightsView(
                    store: viewModel.store.scope(
                        state: \.currentTowerTab,
                        action: TabBarFeature.Action.currentTowerTab
                    )
                )
                .tabItem { Label("Current", systemImage: "building") }
                .tag(Tab.current)

                MonthlyTowerLightsView(
                    store: viewModel.store.scope(
                        state: \.monthlyTowerTab,
                        action: TabBarFeature.Action.monthlyTowerTab
                    )
                )
                .tabItem { Label("Monthly", systemImage: "calendar") }
                .tag(Tab.monthly)
            }.tint(.indigo)
        }
    }
}

struct TabBarFeature_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(viewModel: .shared)
    }
}

struct AppDomain: Reducer {
    typealias State = TabBarFeature.State

    enum Action: Equatable {
        case openMonthView
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .openMonthView:
                state.selectedTab = .monthly
                return .none
            }
        }
    }
}
