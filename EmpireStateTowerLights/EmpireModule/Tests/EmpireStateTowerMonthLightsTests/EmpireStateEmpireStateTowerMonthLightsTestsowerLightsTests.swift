//
//  EmpireStateTowerLightsTests.swift
//  EmpireStateTowerLightsTests
//
//  Created by Thomas Prezioso Jr on 9/3/23.
//

import XCTest
@testable import MonthlyTowerFeature
import ComposableArchitecture
import Models

@MainActor
final class EmpireStateTowerMonthLightsTests: XCTestCase {
    
    func testMonthlyTowerHappyPath() async {
        let store = TestStore(initialState: MonthlyTowerLightsFeature.State()) {
            MonthlyTowerLightsFeature()
        } withDependencies: {
            $0.towerClient = .testValue
        }
        
        let testTower = Tower.monthlyPreview

        await store.send(.onAppear)
        
        await store.receive(.didReceiveData(testTower)) {
            $0.towers = testTower
        }
    }
}
