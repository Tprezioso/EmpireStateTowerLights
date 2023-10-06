//
//  EmpireStateTowerCurrentLightsTest.swift
//  EmpireStateTowerLightsTests
//
//  Created by Thomas Prezioso Jr on 9/8/23.
//

import XCTest
@testable import CurrentTowerFeature
import Models
import ComposableArchitecture

@MainActor
final class EmpireStateTowerCurrentLightsTest: XCTestCase {
    func testCurrentTowerHappyPath() async {
        let store = TestStore(initialState:
                                CurrentTowerLightsFeature.State()) {
            CurrentTowerLightsFeature()
        } withDependencies: {
            $0.currentTowerClient = .testValue
        }

        let testTower = Tower.currentTowerTest

        await store.send(.onAppear)

        await store.receive(.didReceiveData(testTower)) {
            $0.towers = testTower
        }
    }

    func testSwipeBetweenView() async {
        let store = TestStore(initialState:
                                CurrentTowerLightsFeature.State()) {
            CurrentTowerLightsFeature()
        } withDependencies: {
            $0.currentTowerClient = .testValue
        }

        await store.send(.swipedScreenLeft) {
            $0.dateSelection = .tomorrow
        }

        await store.send(.swipedScreenRight) {
            $0.dateSelection = .today
        }

        await store.send(.swipedScreenRight) {
            $0.dateSelection = .yesterday
        }

        await store.send(.swipedScreenLeft) {
            $0.dateSelection = .today
        }
    }
}
