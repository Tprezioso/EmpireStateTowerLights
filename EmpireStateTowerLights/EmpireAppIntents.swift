//
//  EmpireAppIntents.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 12/4/23.
//

import Foundation
import AppIntents
import Observation

struct OpenMonthlyLights: AppIntent {
    static var title: LocalizedStringResource = "Open Monthly Light Schedule"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let tabBarStore = TabBarView.ViewModel.shared
        tabBarStore.store.send(.selectedTabChanged(.monthly))

//        navigationModel.isShowingMonthly = true
//        TabBarView(store: .init(initialState: TabBarFeature.State(selectedTab: .monthly)) {
//            TabBarFeature()
//        })
        return .result()
    }
    @Dependency
    private var navigationModel: NavigationModel
}

@MainActor
@Observable class NavigationModel {
    var isShowingMonthly: Bool

    init(isShowingMonthly: Bool) {
        self.isShowingMonthly = isShowingMonthly
    }
}
