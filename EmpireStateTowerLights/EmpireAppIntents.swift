//
//  EmpireAppIntents.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 12/4/23.
//

import AppIntents
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TowerClient

/// Answers "What color is the Empire State Building tonight?" without opening the app.
struct TonightsLightsIntent: AppIntent {
    static let title: LocalizedStringResource = "Tonight's Tower Lights"
    static let description = IntentDescription("Find out what color the Empire State Building is lit tonight.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        // Qualified because AppIntents has its own `@Dependency` wrapper.
        @ComposableArchitecture.Dependency(\.towerClient) var towerClient
        let lighting = try await towerClient.current().today
        let dialog = IntentDialog(stringLiteral: "Tonight the Empire State Building is lit \(lighting.spokenDescription).")
        return .result(value: lighting.title, dialog: dialog, view: TonightSnippetView(lighting: lighting))
    }
}

/// Opens the app on the lights calendar.
struct OpenMonthlyLights: AppIntent {
    static let title: LocalizedStringResource = "Open Lights Calendar"
    static let description = IntentDescription("Opens the Empire State Building lights calendar.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppStore.shared.send(.open(.calendar))
        return .result()
    }
}

struct EmpireShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TonightsLightsIntent(),
            phrases: [
                "What color is the Empire State Building tonight in \(.applicationName)",
                "What are tonight's \(.applicationName)",
                "Check \(.applicationName)",
            ],
            shortTitle: "Tonight's Lights",
            systemImageName: "building.2.fill"
        )
        AppShortcut(
            intent: OpenMonthlyLights(),
            phrases: [
                "Show the \(.applicationName) calendar",
                "Open \(.applicationName) calendar",
            ],
            shortTitle: "Lights Calendar",
            systemImageName: "calendar"
        )
    }
}

private struct TonightSnippetView: View {
    var lighting: TowerLighting

    var body: some View {
        HStack(spacing: 16) {
            GlowingTowerView(colors: lighting.swatchColors, animatesGlow: false)
                .frame(height: 110)
            VStack(alignment: .leading, spacing: 6) {
                Text("Tonight").eyebrowStyle()
                Text(lighting.title)
                    .font(.display(.title3))
                    .foregroundStyle(.white)
                ColorSwatchRow(colors: lighting.colors, size: 12)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(LinearGradient(colors: [Theme.skyTop, Theme.skyMiddle], startPoint: .top, endPoint: .bottom))
        .environment(\.colorScheme, .dark)
    }
}
