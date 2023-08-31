//
//  EmpireStateTowerLightsApp.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import SwiftUI

@main
struct EmpireStateTowerLightsApp: App {
    var body: some Scene {
        WindowGroup {
            CurrentTowerLightsView(store: .init(initialState: CurrentTowerLightsFeature.State()) {
                CurrentTowerLightsFeature()
            })
        }
    }
}