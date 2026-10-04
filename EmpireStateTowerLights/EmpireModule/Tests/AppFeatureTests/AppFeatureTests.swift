@testable import AppFeature
import ComposableArchitecture
import Models
import XCTest

@MainActor
final class AppFeatureTests: XCTestCase {
    func testDeepLinksSwitchTabsAndDismissSheets() async {
        var state = AppFeature.State()
        state.tonight.detail = .preview
        let store = TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.openURL(URL(string: "towerlights://calendar")!))
        await store.receive(\.open) {
            $0.selectedTab = .calendar
            $0.tonight.detail = nil
        }

        await store.send(.openURL(URL(string: "towerlights://tonight")!))
        await store.receive(\.open) {
            $0.selectedTab = .tonight
        }
    }

    func testUnknownURLsAreIgnored() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        await store.send(.openURL(URL(string: "towerlights://nope")!))
        await store.send(.openURL(URL(string: "https://www.esbnyc.com")!))
    }
}

@MainActor
final class AppFeatureAboutTests: XCTestCase {
    func testAboutButtonPresentsSheetAndDeepLinkDismissesIt() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.tonight(.aboutButtonTapped))
        await store.receive(\.tonight.delegate.showAbout) {
            $0.about = .init()
        }

        await store.send(.open(.calendar)) {
            $0.selectedTab = .calendar
            $0.about = nil
        }
    }

    func testAppLaunchFinishesTransactions() async {
        let finished = LockIsolated(false)
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.tipJar.finishTransactions = { finished.setValue(true) }
        }

        await store.send(.appLaunched)
        XCTAssertTrue(finished.value)
    }
}
