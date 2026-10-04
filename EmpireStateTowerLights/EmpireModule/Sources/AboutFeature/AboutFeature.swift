//
//  AboutFeature.swift
//  EmpireStateTowerLights
//

import ComposableArchitecture
import Foundation

@Reducer
public struct AboutFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedIcon: AppIcon = .midnight
        public var tips: [Tip]?
        public var tipsError: String?
        public var purchasingTipID: Tip.ID?
        public var purchaseMessage: String?
        /// Incremented on every completed tip so the view can celebrate.
        public var thankYouCount = 0

        public init() {}
    }

    public enum Action {
        case task
        case currentIconLoaded(AppIcon)
        case iconTapped(AppIcon)
        case iconChangeFailed(previous: AppIcon)
        case tipsResponse(Result<[Tip], any Error>)
        case retryTipsButtonTapped
        case tipTapped(Tip)
        case purchaseResponse(Result<TipPurchaseResult, any Error>)
        case doneButtonTapped
    }

    @Dependency(\.appIcon) var appIcon
    @Dependency(\.tipJar) var tipJar
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .run { send in await send(.currentIconLoaded(await appIcon.current())) },
                    loadTips(&state)
                )

            case let .currentIconLoaded(icon):
                state.selectedIcon = icon
                return .none

            case let .iconTapped(icon):
                guard icon != state.selectedIcon else { return .none }
                let previous = state.selectedIcon
                state.selectedIcon = icon
                return .run { _ in
                    try await appIcon.set(icon)
                } catch: { _, send in
                    await send(.iconChangeFailed(previous: previous))
                }

            case let .iconChangeFailed(previous):
                state.selectedIcon = previous
                return .none

            case let .tipsResponse(.success(tips)):
                state.tips = tips
                state.tipsError = tips.isEmpty ? "Tips aren't available right now." : nil
                return .none

            case .tipsResponse(.failure):
                state.tipsError = "Couldn't reach the App Store. Check your connection and try again."
                return .none

            case .retryTipsButtonTapped:
                return loadTips(&state)

            case let .tipTapped(tip):
                guard state.purchasingTipID == nil else { return .none }
                state.purchasingTipID = tip.id
                state.purchaseMessage = nil
                return .run { send in
                    await send(.purchaseResponse(Result { try await tipJar.purchase(tip.id) }))
                }

            case let .purchaseResponse(.success(result)):
                state.purchasingTipID = nil
                switch result {
                case .success:
                    state.thankYouCount += 1
                    state.purchaseMessage = "Thank you! You just made the crown glow a little brighter. 💛"
                case .pending:
                    state.purchaseMessage = "Your tip is pending approval. Thank you!"
                case .cancelled:
                    break
                }
                return .none

            case let .purchaseResponse(.failure(error)):
                state.purchasingTipID = nil
                state.purchaseMessage = error.localizedDescription
                return .none

            case .doneButtonTapped:
                return .run { _ in await dismiss() }
            }
        }
    }

    private func loadTips(_ state: inout State) -> Effect<Action> {
        state.tipsError = nil
        return .run { send in
            await send(.tipsResponse(Result { try await tipJar.tips() }))
        }
    }
}
