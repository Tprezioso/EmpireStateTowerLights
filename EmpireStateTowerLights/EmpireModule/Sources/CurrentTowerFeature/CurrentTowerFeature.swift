//
//  CurrentTowerFeature.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/28/23.
//

import ComposableArchitecture
import Foundation
import Models
import TowerClient

@Reducer
public struct CurrentTowerFeature {
    @ObservableState
    public struct State: Equatable {
        public var lights: CurrentLights?
        public var isLoading = false
        public var errorMessage: String?
        public var selectedDay: Day = .today
        public var lastUpdated: Date?
        public var detail: TowerLighting?

        public init(lights: CurrentLights? = nil) {
            self.lights = lights
        }

        /// The days we have data for, in display order.
        public var availableDays: [Day] {
            guard let lights else { return [] }
            return Day.allCases.filter { lights.lighting(for: $0) != nil }
        }

        public var selectedLighting: TowerLighting? {
            lights?.lighting(for: selectedDay)
        }
    }

    public enum Day: String, Hashable, CaseIterable, Sendable {
        case yesterday, today, tomorrow

        public var title: String {
            switch self {
            case .yesterday: "Last Night"
            case .today: "Tonight"
            case .tomorrow: "Tomorrow"
            }
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case task
        case sceneBecameActive
        case refresh
        case retryButtonTapped
        case response(Result<CurrentLights, any Error>)
        case lightingTapped(TowerLighting)
    }

    enum CancelID { case load }

    /// How long fetched data is considered fresh when returning to the app.
    static let staleInterval: TimeInterval = 15 * 60

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
                guard state.lights == nil else { return .none }
                return load(&state)

            case .sceneBecameActive:
                guard let lastUpdated = state.lastUpdated else { return load(&state) }
                let isStale = now.timeIntervalSince(lastUpdated) > Self.staleInterval
                    || CalendarDay(now) != CalendarDay(lastUpdated)
                return isStale ? load(&state) : .none

            case .refresh, .retryButtonTapped:
                return load(&state)

            case let .response(.success(lights)):
                state.isLoading = false
                state.errorMessage = nil
                state.lights = lights
                state.lastUpdated = now
                if lights.lighting(for: state.selectedDay) == nil {
                    state.selectedDay = .today
                }
                return .none

            case let .response(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .lightingTapped(lighting):
                state.detail = lighting
                return .none
            }
        }
    }

    private func load(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        return .run { send in
            await send(.response(Result { try await towerClient.current() }))
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}

extension CurrentLights {
    public func lighting(for day: CurrentTowerFeature.Day) -> TowerLighting? {
        switch day {
        case .yesterday: yesterday
        case .today: today
        case .tomorrow: tomorrow
        }
    }
}
