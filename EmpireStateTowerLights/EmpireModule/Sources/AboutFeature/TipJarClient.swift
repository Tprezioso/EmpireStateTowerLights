//
//  TipJarClient.swift
//  EmpireStateTowerLights
//

import Dependencies
import DependenciesMacros
import Foundation
import StoreKit

/// A consumable "tip" in-app purchase. Tips unlock nothing; they just say thanks.
public struct Tip: Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var displayPrice: String

    public init(id: String, displayName: String, displayPrice: String) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
    }

    public static let coffeeID = "com.Swifttom.EmpireStateTowerLights.tip.coffee"
    public static let sliceID = "com.Swifttom.EmpireStateTowerLights.tip.slice"
    public static let cheesecakeID = "com.Swifttom.EmpireStateTowerLights.tip.cheesecake"
    public static let allIDs = [coffeeID, sliceID, cheesecakeID]

    public var emoji: String {
        switch id {
        case Self.coffeeID: "☕️"
        case Self.sliceID: "🍕"
        case Self.cheesecakeID: "🍰"
        default: "💛"
        }
    }

    public static let previews = [
        Tip(id: coffeeID, displayName: "Cup of Coffee", displayPrice: "$0.99"),
        Tip(id: sliceID, displayName: "Slice of Pizza", displayPrice: "$2.99"),
        Tip(id: cheesecakeID, displayName: "New York Cheesecake", displayPrice: "$9.99"),
    ]
}

public enum TipPurchaseResult: Equatable, Sendable {
    case success
    case cancelled
    /// Waiting on something like Ask to Buy. StoreKit delivers it later via `Transaction.updates`.
    case pending
}

public enum TipJarError: LocalizedError, Equatable {
    case productNotFound
    case unverified

    public var errorDescription: String? {
        switch self {
        case .productNotFound: "That tip isn't available right now."
        case .unverified: "The App Store couldn't verify that purchase."
        }
    }
}

@DependencyClient
public struct TipJarClient: Sendable {
    /// Available tips, cheapest first.
    public var tips: @Sendable () async throws -> [Tip]
    public var purchase: @Sendable (_ id: Tip.ID) async throws -> TipPurchaseResult
    /// Finishes any unfinished transactions, then keeps finishing new ones for the life of the app.
    public var finishTransactions: @Sendable () async -> Void
}

extension TipJarClient: DependencyKey {
    public static let liveValue = TipJarClient(
        tips: {
            try await Product.products(for: Tip.allIDs)
                .sorted { $0.price < $1.price }
                .map { Tip(id: $0.id, displayName: $0.displayName, displayPrice: $0.displayPrice) }
        },
        purchase: { id in
            guard let product = try await Product.products(for: [id]).first else {
                throw TipJarError.productNotFound
            }
            switch try await product.purchase() {
            case let .success(verification):
                guard case let .verified(transaction) = verification else { throw TipJarError.unverified }
                await transaction.finish()
                return .success
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .cancelled
            }
        },
        finishTransactions: {
            for await result in Transaction.unfinished {
                if case let .verified(transaction) = result { await transaction.finish() }
            }
            for await result in Transaction.updates {
                if case let .verified(transaction) = result { await transaction.finish() }
            }
        }
    )

    public static let previewValue = TipJarClient(
        tips: { Tip.previews },
        purchase: { _ in
            try await Task.sleep(for: .seconds(1))
            return .success
        },
        finishTransactions: {}
    )

    public static let testValue = TipJarClient()
}

extension DependencyValues {
    public var tipJar: TipJarClient {
        get { self[TipJarClient.self] }
        set { self[TipJarClient.self] = newValue }
    }
}
