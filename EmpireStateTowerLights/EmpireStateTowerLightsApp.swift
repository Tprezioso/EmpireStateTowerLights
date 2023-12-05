//
//  EmpireStateTowerLightsApp.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import SwiftUI
import AppIntents

@main
struct EmpireStateTowerLightsApp: App {
    @State var isShowingSplash = true
    var showMonthly: NavigationModel

    init() {
        let navigationManager = NavigationModel(isShowingMonthly: false)
        showMonthly = navigationManager
        AppDependencyManager.shared.add(dependency: navigationManager)
    }

    var body: some Scene {
        WindowGroup {
            if isShowingSplash {
                SplashScreen(isShowing: $isShowingSplash)
            } else {
                if showMonthly.isShowingMonthly {
                    TabBarView(store: .init(initialState: TabBarFeature.State(selectedTab: .monthly)) {
                        TabBarFeature()
                    })

                } else {
                    TabBarView(store: .init(initialState: TabBarFeature.State()) {
                        TabBarFeature()
                    })
                }
            }
        }
    }
}
