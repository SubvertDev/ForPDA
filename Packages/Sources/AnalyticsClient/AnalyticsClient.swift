//
//  AnalyticsClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 24.03.2024.
//

import Foundation
import ComposableArchitecture
import PersistenceKeys
import Models
import AppMetricaCore
import AppMetricaCrashes
import OSLog

public enum AnalyticsError: Error {
    case brokenArticle(URL)
    case apiFailure(any Error)
}

@DependencyClient
public struct AnalyticsClient: Sendable {
    public var configure: @Sendable () -> Void
    public var identify: @Sendable (_ id: String) -> Void
    public var logout: @Sendable () -> Void
    public var log: @Sendable (any Event) -> Void
    public var capture: @Sendable (any Error) -> Void
}

extension AnalyticsClient: DependencyKey {
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Analytics")
    
    public static var liveValue: Self {
        return AnalyticsClient(
            configure: {
                configureAnalytics()
            },
            identify: { id in
                logger.info("Identifying user with id: \(id)")
                AppMetrica.userProfileID = id
            },
            logout: {
                @Shared(.appStorage("analytics_id")) var analyticsId = UUID().uuidString
                logger.info("Analytics has been reset after logout to \(analyticsId)")
                AppMetrica.userProfileID = analyticsId
            },
            log: { event in
                logger.info("\(event.name) \(event.properties.map { "(\($0))" } ?? "")")
                AppMetrica.reportEvent(name: event.name, parameters: event.properties)
            },
            capture: { error in
                logger.error("\(error)\nLocalized: \(error.localizedDescription)")
                AppMetricaCrashes.crashes().report(nserror: error)
            }
        )
    }
    
    public static let previewValue = Self(
        configure: {},
        identify: { _ in },
        logout: {},
        log: { event in
            if let properties = event.properties {
                print("[Analytics] \(event.name) (\(properties))")
            } else {
                print("[Analytics] \(event.name)")
            }
        },
        capture: { error in
            print("[Crashlytics] \(error)")
        }
    )
}

// MARK: - Extension

extension AnalyticsClient {
    
    private static func configureAnalytics() {
        @Shared(.appStorage("analytics_id")) var analyticsId = UUID().uuidString
        @Shared(.userSession) var userSession
        
        let userProfileID: String
        if let sessionUserId = userSession?.userId {
            logger.info("User session found, setting AppMetrica's id to \(sessionUserId)")
            userProfileID = String(sessionUserId)
        } else {
            logger.info("User session not found, defaulting to \(analyticsId)")
            userProfileID = analyticsId
        }

        if let configuration = AppMetricaConfiguration(apiKey: Secrets.appmetricaToken) {
            configuration.dataSendingEnabled = !isDebug
            configuration.userProfileID = userProfileID
            AppMetrica.activate(with: configuration)
        }
    }
}

public extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}

// MARK: - Helpers

// TODO: Move to another place
private var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}
