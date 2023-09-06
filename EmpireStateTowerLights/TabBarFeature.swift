//
//  TabBarFeature.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/5/23.
//

import ComposableArchitecture
import SwiftUI

struct TabBarFeature: Reducer {
    struct State: Equatable {
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
        Reduce<State, Action> { state, action in
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
    let store: StoreOf<TabBarFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: \.selectedTab) { viewStore in
            TabView(selection: viewStore.binding(send: TabBarFeature.Action.selectedTabChanged)) {
                CurrentTowerLightsView(
                    store: self.store.scope(
                        state: \.currentTowerTab,
                        action: TabBarFeature.Action.currentTowerTab
                    )
                )
                .tabItem { Text("Current") }
                .tag(Tab.current)
                
                MonthlyTowerLightsView(
                    store: self.store.scope(
                        state: \.monthlyTowerTab,
                        action: TabBarFeature.Action.monthlyTowerTab
                    )
                )
                .tabItem { Text("Monthly") }
                .tag(Tab.monthly)
                
            }
        }
    }
}

struct TabBarFeature_Previews: PreviewProvider {
    static var previews: some View {
//        ContentView(
//              store: Store(
//                initialState: AppFeature.State(),
//                reducer: AppFeature()
//              )
//            )
        TabBarView(store: .init(initialState: TabBarFeature.State()) {
            TabBarFeature()
        })
    }
}
