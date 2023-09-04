//
//  EmpireStateTowerLightsTests.swift
//  EmpireStateTowerLightsTests
//
//  Created by Thomas Prezioso Jr on 9/3/23.
//

import XCTest
@testable import EmpireStateTowerLights
import ComposableArchitecture

@MainActor
final class EmpireStateTowerMonthLightsTests: XCTestCase {
    
    func testCurrentTowerHappyPath() async {
        let store = TestStore(initialState: MonthlyTowerLightsFeature.State()) {
            MonthlyTowerLightsFeature()
        } withDependencies: {
            $0.towerClient = .testValue
        }
        
        let testTower = [Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")]

        await store.send(.onAppear)
        
        await store.receive(.didReceiveData(testTower)) {
            $0.towers = testTower
        }
    }
}
