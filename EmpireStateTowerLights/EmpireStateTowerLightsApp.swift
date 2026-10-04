//
//  EmpireStateTowerLightsApp.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import AppFeature
import ComposableArchitecture
import SwiftUI

@MainActor
enum AppStore {
    /// The single app store, shared so App Intents can drive navigation.
    static let shared = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
}

@main
struct EmpireStateTowerLightsApp: App {
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppView(store: AppStore.shared)
                    .task { await AppStore.shared.send(.appLaunched).finish() }

                if isShowingSplash {
                    SplashScreen {
                        withAnimation(.easeInOut(duration: 0.45)) { isShowingSplash = false }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
