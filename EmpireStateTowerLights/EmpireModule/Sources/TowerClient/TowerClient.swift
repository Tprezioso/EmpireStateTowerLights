//
//  TowerClient.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/3/23.
//

import Dependencies
import DependenciesMacros
import Foundation
import Models
import OSLog

@DependencyClient
public struct TowerClient: Sendable {
    /// Yesterday's, today's and tomorrow's lighting from the tower lights page.
    public var current: @Sendable () async throws -> CurrentLights
    /// Every special lighting scheduled for a month.
    public var month: @Sendable (_ month: YearMonth) async throws -> [TowerLighting]
}

public enum TowerError: LocalizedError, Equatable, Sendable {
    case badResponse(statusCode: Int)
    case parsing

    public var errorDescription: String? {
        switch self {
        case .badResponse:
            return "The Empire State Building website isn't responding right now."
        case .parsing:
            return "We couldn't read the light schedule. The website may have changed."
        }
    }
}

private let logger = Logger(subsystem: "EmpireStateTowerLights", category: "TowerClient")

extension TowerClient: DependencyKey {
    public static let baseURL = URL(string: "https://www.esbnyc.com")!

    public static let liveValue: TowerClient = {
        let session: URLSession = {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            configuration.requestCachePolicy = .reloadRevalidatingCacheData
            return URLSession(configuration: configuration)
        }()

        @Sendable func html(at path: String) async throws -> String {
            let url = baseURL.appending(path: path)
            let (data, response) = try await session.data(from: url)
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                logger.error("\(url) returned \(response.statusCode)")
                throw TowerError.badResponse(statusCode: response.statusCode)
            }
            guard let html = String(data: data, encoding: .utf8) else { throw TowerError.parsing }
            return html
        }

        return TowerClient(
            current: {
                let page = try await html(at: "about/tower-lights")
                return try TowerParser.parseCurrent(html: page, baseURL: baseURL, fallbackToday: CalendarDay(Date()))
            },
            month: { month in
                let page = try await html(at: "about/tower-lights/calendar/\(month.pathComponent)")
                return try TowerParser.parseMonth(html: page, baseURL: baseURL)
            }
        )
    }()

    public static let previewValue = TowerClient(
        current: { .preview },
        month: { _ in TowerLighting.previewMonth }
    )
}

extension TowerClient: TestDependencyKey {
    public static let testValue = TowerClient()
}

extension DependencyValues {
    public var towerClient: TowerClient {
        get { self[TowerClient.self] }
        set { self[TowerClient.self] = newValue }
    }
}
