//
//  AppIconClient.swift
//  EmpireStateTowerLights
//

import Dependencies
import DependenciesMacros
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// The app's selectable icons. Each alternate matches an `AppIcon-<assetSuffix>` set in the app's asset catalog.
public enum AppIcon: String, CaseIterable, Identifiable, Sendable {
    case midnight, classic, patriot, pinkRibbon, emerald, pride, signatureWhite

    public var id: Self { self }

    var assetSuffix: String {
        switch self {
        case .midnight: "Midnight"
        case .classic: "Classic"
        case .patriot: "Patriot"
        case .pinkRibbon: "PinkRibbon"
        case .emerald: "Emerald"
        case .pride: "Pride"
        case .signatureWhite: "SignatureWhite"
        }
    }

    public var title: String {
        switch self {
        case .midnight: "Midnight"
        case .classic: "Classic"
        case .patriot: "Patriot"
        case .pinkRibbon: "Pink Ribbon"
        case .emerald: "Emerald"
        case .pride: "Pride"
        case .signatureWhite: "Signature White"
        }
    }

    /// `nil` for the primary icon.
    public var alternateIconName: String? {
        self == .midnight ? nil : "AppIcon-\(assetSuffix)"
    }

    public init(alternateIconName: String?) {
        self = Self.allCases.first { $0.alternateIconName == alternateIconName } ?? .midnight
    }

    var previewImageName: String { "IconPreview-\(assetSuffix)" }
}

@DependencyClient
public struct AppIconClient: Sendable {
    public var current: @Sendable () async -> AppIcon = { .midnight }
    public var set: @Sendable (_ icon: AppIcon) async throws -> Void
}

extension AppIconClient: DependencyKey {
    public static let liveValue: AppIconClient = {
        #if os(iOS)
        return AppIconClient(
            current: { await MainActor.run { AppIcon(alternateIconName: UIApplication.shared.alternateIconName) } },
            set: { icon in try await setAlternateIcon(icon.alternateIconName) }
        )
        #else
        return AppIconClient(current: { .midnight }, set: { _ in })
        #endif
    }()

    public static let testValue = AppIconClient()
    public static let previewValue = AppIconClient(current: { .midnight }, set: { _ in })
}

#if os(iOS)
@MainActor
private func setAlternateIcon(_ name: String?) async throws {
    guard UIApplication.shared.supportsAlternateIcons else { return }
    try await UIApplication.shared.setAlternateIconName(name)
}
#endif

extension DependencyValues {
    public var appIcon: AppIconClient {
        get { self[AppIconClient.self] }
        set { self[AppIconClient.self] = newValue }
    }
}
