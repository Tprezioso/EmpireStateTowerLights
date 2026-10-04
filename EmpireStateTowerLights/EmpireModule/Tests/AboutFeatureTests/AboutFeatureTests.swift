@testable import AboutFeature
import ComposableArchitecture
import XCTest

@MainActor
final class AboutFeatureTests: XCTestCase {
    func testLoadsCurrentIconAndTips() async {
        let store = TestStore(initialState: AboutFeature.State()) {
            AboutFeature()
        } withDependencies: {
            $0.appIcon.current = { .pride }
            $0.tipJar.tips = { Tip.previews }
        }

        await store.send(.task)
        await store.receive(\.currentIconLoaded) { $0.selectedIcon = .pride }
        await store.receive(\.tipsResponse.success) { $0.tips = Tip.previews }
    }

    func testChangingIconRollsBackOnFailure() async {
        struct Failure: Error {}
        let setIcons = LockIsolated<[AppIcon]>([])
        let store = TestStore(initialState: AboutFeature.State()) {
            AboutFeature()
        } withDependencies: {
            $0.appIcon.set = { icon in setIcons.withValue { $0.append(icon) } }
        }

        await store.send(.iconTapped(.patriot)) { $0.selectedIcon = .patriot }
        XCTAssertEqual(setIcons.value, [.patriot])

        // Tapping the current icon does nothing.
        await store.send(.iconTapped(.patriot))

        store.dependencies.appIcon.set = { _ in throw Failure() }
        await store.send(.iconTapped(.emerald)) { $0.selectedIcon = .emerald }
        await store.receive(\.iconChangeFailed) { $0.selectedIcon = .patriot }
    }

    func testSuccessfulTipCelebrates() async {
        let store = TestStore(initialState: AboutFeature.State()) {
            AboutFeature()
        } withDependencies: {
            $0.tipJar.purchase = { _ in .success }
        }

        await store.send(.tipTapped(Tip.previews[1])) { $0.purchasingTipID = Tip.sliceID }
        await store.receive(\.purchaseResponse.success) {
            $0.purchasingTipID = nil
            $0.thankYouCount = 1
            $0.purchaseMessage = "Thank you! You just made the crown glow a little brighter. 💛"
        }
    }

    func testCancelledPendingAndFailedTips() async {
        let store = TestStore(initialState: AboutFeature.State()) {
            AboutFeature()
        } withDependencies: {
            $0.tipJar.purchase = { _ in .cancelled }
        }

        await store.send(.tipTapped(Tip.previews[0])) { $0.purchasingTipID = Tip.coffeeID }
        await store.receive(\.purchaseResponse.success) { $0.purchasingTipID = nil }

        store.dependencies.tipJar.purchase = { _ in .pending }
        await store.send(.tipTapped(Tip.previews[0])) { $0.purchasingTipID = Tip.coffeeID }
        await store.receive(\.purchaseResponse.success) {
            $0.purchasingTipID = nil
            $0.purchaseMessage = "Your tip is pending approval. Thank you!"
        }

        store.dependencies.tipJar.purchase = { _ in throw TipJarError.productNotFound }
        await store.send(.tipTapped(Tip.previews[0])) {
            $0.purchasingTipID = Tip.coffeeID
            $0.purchaseMessage = nil
        }
        await store.receive(\.purchaseResponse.failure) {
            $0.purchasingTipID = nil
            $0.purchaseMessage = TipJarError.productNotFound.localizedDescription
        }
    }

    func testIconNamesMatchAssetCatalog() {
        XCTAssertNil(AppIcon.midnight.alternateIconName)
        XCTAssertEqual(AppIcon.pinkRibbon.alternateIconName, "AppIcon-PinkRibbon")
        XCTAssertEqual(AppIcon(alternateIconName: "AppIcon-Pride"), .pride)
        XCTAssertEqual(AppIcon(alternateIconName: nil), .midnight)
        XCTAssertEqual(AppIcon(alternateIconName: "Unknown"), .midnight)
    }
}
