import ComposableArchitecture
@testable import CurrentTowerFeature
import Foundation
import Models
import TowerClient
import XCTest

@MainActor
final class CurrentTowerFeatureTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_791_000_000)

    func testLoadsOnFirstAppearanceOnly() async {
        let store = TestStore(initialState: CurrentTowerFeature.State()) {
            CurrentTowerFeature()
        } withDependencies: {
            $0.towerClient.current = { .preview }
            $0.date.now = now
        }

        await store.send(.task) { $0.isLoading = true }
        await store.receive(\.response.success) {
            $0.isLoading = false
            $0.lights = .preview
            $0.lastUpdated = self.now
        }
        // Appearing again (e.g. switching tabs) doesn't refetch.
        await store.send(.task)
    }

    func testFailureShowsErrorAndRetryRecovers() async {
        let store = TestStore(initialState: CurrentTowerFeature.State()) {
            CurrentTowerFeature()
        } withDependencies: {
            $0.towerClient.current = { throw TowerError.parsing }
            $0.date.now = now
        }

        await store.send(.task) { $0.isLoading = true }
        await store.receive(\.response.failure) {
            $0.isLoading = false
            $0.errorMessage = TowerError.parsing.localizedDescription
        }

        store.dependencies.towerClient.current = { .preview }
        await store.send(.retryButtonTapped) { $0.isLoading = true }
        await store.receive(\.response.success) {
            $0.isLoading = false
            $0.errorMessage = nil
            $0.lights = .preview
            $0.lastUpdated = self.now
        }
    }

    func testSceneActiveOnlyRefreshesStaleData() async {
        var state = CurrentTowerFeature.State(lights: .preview)
        state.lastUpdated = now
        let store = TestStore(initialState: state) {
            CurrentTowerFeature()
        } withDependencies: {
            $0.towerClient.current = { .preview }
            $0.date.now = now.addingTimeInterval(60)
        }

        // Fresh: nothing happens.
        await store.send(.sceneBecameActive)

        // Stale: refetch.
        let later = now.addingTimeInterval(CurrentTowerFeature.staleInterval + 1)
        store.dependencies.date.now = later
        await store.send(.sceneBecameActive) { $0.isLoading = true }
        await store.receive(\.response.success) {
            $0.isLoading = false
            $0.lastUpdated = later
        }
    }

    func testSelectingDayAndOpeningDetail() async {
        let store = TestStore(initialState: CurrentTowerFeature.State(lights: .preview)) {
            CurrentTowerFeature()
        }

        await store.send(.binding(.set(\.selectedDay, .tomorrow))) {
            $0.selectedDay = .tomorrow
        }
        XCTAssertEqual(store.state.selectedLighting, CurrentLights.preview.tomorrow)

        await store.send(.lightingTapped(.preview)) {
            $0.detail = .preview
        }
    }

    func testMissingYesterdayIsNotOffered() {
        var lights = CurrentLights.preview
        lights.yesterday = nil
        XCTAssertEqual(CurrentTowerFeature.State(lights: lights).availableDays, [.today, .tomorrow])
    }
}
