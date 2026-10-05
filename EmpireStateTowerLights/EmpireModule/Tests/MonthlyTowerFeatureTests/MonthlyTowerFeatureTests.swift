import ComposableArchitecture
import Foundation
import Models
@testable import MonthlyTowerFeature
import TowerClient
import XCTest

@MainActor
final class MonthlyTowerFeatureTests: XCTestCase {
    /// 2026-10-03 noon in New York.
    let now = CalendarDay(year: 2026, month: 10, day: 3).date.addingTimeInterval(12 * 60 * 60)
    let october = YearMonth(year: 2026, month: 10)

    func testLoadsCurrentMonthAndNavigates() async {
        let store = TestStore(initialState: MonthlyTowerFeature.State()) {
            MonthlyTowerFeature()
        } withDependencies: {
            $0.date.now = now
            $0.towerClient.month = { month in
                month == YearMonth(year: 2026, month: 10) ? TowerLighting.previewMonth : []
            }
        }

        await store.send(.task) {
            $0.today = CalendarDay(year: 2026, month: 10, day: 3)
            $0.month = self.october
            $0.isLoading = true
        }
        await store.receive(\.response) {
            $0.isLoading = false
            $0.lightingsByMonth[self.october] = TowerLighting.previewMonth
            $0.lastUpdated = self.now
        }
        XCTAssertTrue(store.state.isShowingCurrentMonth)

        // An empty month is loaded and shown as empty, not as an error.
        await store.send(.nextMonthTapped) {
            $0.month = self.october.next
            $0.isLoading = true
        }
        await store.receive(\.response) {
            $0.isLoading = false
            $0.lightingsByMonth[self.october.next] = []
        }
        XCTAssertEqual(store.state.lightings, [])

        // Returning to a cached month doesn't refetch.
        await store.send(.currentMonthTapped) {
            $0.month = self.october
        }
    }

    func testFailureForCurrentMonthShowsError() async {
        let store = TestStore(initialState: MonthlyTowerFeature.State()) {
            MonthlyTowerFeature()
        } withDependencies: {
            $0.date.now = now
            $0.towerClient.month = { _ in throw TowerError.badResponse(statusCode: 500) }
        }

        await store.send(.task) {
            $0.today = CalendarDay(year: 2026, month: 10, day: 3)
            $0.month = self.october
            $0.isLoading = true
        }
        await store.receive(\.response) {
            $0.isLoading = false
            $0.errorMessage = TowerError.badResponse(statusCode: 500).localizedDescription
        }
    }
}
