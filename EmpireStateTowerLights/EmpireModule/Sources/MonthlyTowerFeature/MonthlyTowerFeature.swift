//
//  MonthlyTowerFeature.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import ComposableArchitecture
import Foundation
import Models
import TowerClient

@Reducer
public struct MonthlyTowerFeature {
    @ObservableState
    public struct State: Equatable {
        /// The month being shown. `nil` until the feature first appears, then the current month.
        public var month: YearMonth?
        public var today: CalendarDay?
        public var lightingsByMonth: [YearMonth: [TowerLighting]] = [:]
        public var isLoading = false
        public var errorMessage: String?
        public var detail: TowerLighting?
        var lastUpdated: Date?

        public init(month: YearMonth? = nil) {
            self.month = month
        }

        public var lightings: [TowerLighting]? {
            month.flatMap { lightingsByMonth[$0] }
        }

        public var isShowingCurrentMonth: Bool {
            month == today?.yearMonth
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case task
        case sceneBecameActive
        case previousMonthTapped
        case nextMonthTapped
        case currentMonthTapped
        case refresh
        case retryButtonTapped
        case response(YearMonth, Result<[TowerLighting], any Error>)
        case lightingTapped(TowerLighting)
    }

    enum CancelID { case load }

    static let staleInterval: TimeInterval = 60 * 60

    @Dependency(\.towerClient) var towerClient
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .task:
                state.today = CalendarDay(now)
                if state.month == nil {
                    state.month = state.today?.yearMonth
                }
                return state.lightings == nil ? load(&state) : .none

            case .sceneBecameActive:
                let previousToday = state.today
                state.today = CalendarDay(now)
                // Keep following "this month" across a month boundary.
                if state.month == previousToday?.yearMonth {
                    state.month = state.today?.yearMonth
                }
                let isStale = state.lastUpdated.map { now.timeIntervalSince($0) > Self.staleInterval } ?? true
                if isStale {
                    state.lightingsByMonth = state.lightingsByMonth.filter { $0.key == state.month }
                    return load(&state)
                }
                return state.lightings == nil ? load(&state) : .none

            case .previousMonthTapped:
                return show(state.month?.previous, &state)

            case .nextMonthTapped:
                return show(state.month?.next, &state)

            case .currentMonthTapped:
                return show(state.today?.yearMonth, &state)

            case .refresh, .retryButtonTapped:
                return load(&state)

            case let .response(month, .success(lightings)):
                state.lightingsByMonth[month] = lightings
                state.lastUpdated = now
                if month == state.month {
                    state.isLoading = false
                    state.errorMessage = nil
                }
                return .none

            case let .response(month, .failure(error)):
                if month == state.month {
                    state.isLoading = false
                    state.errorMessage = error.localizedDescription
                }
                return .none

            case let .lightingTapped(lighting):
                state.detail = lighting
                return .none
            }
        }
    }

    private func show(_ month: YearMonth?, _ state: inout State) -> Effect<Action> {
        guard let month else { return .none }
        state.month = month
        state.errorMessage = nil
        if state.lightingsByMonth[month] != nil {
            state.isLoading = false
            return .cancel(id: CancelID.load)
        }
        return load(&state)
    }

    private func load(_ state: inout State) -> Effect<Action> {
        guard let month = state.month else { return .none }
        state.isLoading = true
        return .run { send in
            await send(.response(month, Result { try await towerClient.month(month) }))
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}
