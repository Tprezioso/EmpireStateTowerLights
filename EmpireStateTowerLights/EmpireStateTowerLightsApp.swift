//
//  EmpireStateTowerLightsApp.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import SwiftUI
import AppIntents
import ComposableArchitecture

@main
struct EmpireStateTowerLightsApp: App {
    @State var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            if isShowingSplash {
                SplashScreen(isShowing: $isShowingSplash)
            } else {
                TabBarView()
            }
        }
    }
}
