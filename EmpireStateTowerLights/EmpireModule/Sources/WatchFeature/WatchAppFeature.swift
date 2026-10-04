//
//  WatchAppFeature.swift
//  EmpireStateTowerLights
//

import ComposableArchitecture
import CurrentTowerFeature
import Foundation
import MonthlyTowerFeature

/// The Apple Watch app: the same Tonight and Calendar logic as the phone, with watch navigation.
@Reducer
public struct WatchAppFeature {
    @ObservableState
    public struct State: Equatable {
        public var tonight = CurrentTowerFeature.State()
        public var calendar = MonthlyTowerFeature.State()
        public var isShowingCalendar = false

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case tonight(CurrentTowerFeature.Action)
        case calendar(MonthlyTowerFeature.Action)
        case calendarButtonTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.tonight, action: \.tonight) {
            CurrentTowerFeature()
        }
        Scope(state: \.calendar, action: \.calendar) {
            MonthlyTowerFeature()
        }
        Reduce { state, action in
            switch action {
            case .calendarButtonTapped:
                state.isShowingCalendar = true
                return .none

            case .binding, .tonight, .calendar:
                return .none
            }
        }
    }
}
