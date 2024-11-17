//
//  AnalyticsClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 24.03.2024.
//

import Foundation
import ComposableArchitecture
import PersistenceKeys
import LoggerClient
import Models
import Mixpanel
import Sentry
import OSLog

@DependencyClient
public struct AnalyticsClient: Sendable {
    public var configure: @Sendable (AnalyticsConfiguration) -> Void
    public var identify: @Sendable (_ id: String) -> Void
    public var logout: @Sendable () -> Void
    public var log: @Sendable (any Event) -> Void
    public var capture: @Sendable (any Error) -> Void
}

public extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}

extension AnalyticsClient: DependencyKey {
    
    public static var liveValue: Self {
        @Dependency(\.logger[.analytics]) var logger
        
        return AnalyticsClient(
            configure: { config in
                @Shared(.appStorage("analytics_id")) var analyticsId = UUID().uuidString
                
                configureMixpanel(
                    id: analyticsId,
                    isEnabled: config.isAnalyticsEnabled
                )
                logger.info("Analytics has been succesfully configured. Enabled: \(config.isAnalyticsEnabled)")
                
                configureSentry(
                    id: analyticsId,
                    isEnabled: config.isCrashlyticsEnabled,
                    isDebugEnabled: config.isCrashlyticsDebugEnabled
                )
                logger.info("Crashlytics has been successfully configured. Enabled: \(config.isCrashlyticsEnabled) / Debug: \(config.isCrashlyticsDebugEnabled)")
            },
            identify: { id in
                logger.info("Identifying user with id: \(id)")
                Mixpanel.mainInstance().identify(distinctId: id)
            },
            logout: {
                logger.info("Analytics has been reset after logout")
                Mixpanel.mainInstance().reset()
            },
            log: { event in
                logger.info("\(event.name) \(event.properties.map { "(\($0))" } ?? "")")
                Mixpanel.mainInstance().track(event: event.name, properties: event.properties)
            },
            capture: { error in
                logger.error("Captured error via Sentry: \(error)")
                SentrySDK.capture(error: error)
            }
        )
    }
    
    public static let previewValue = Self(
        configure: { _ in },
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
            print("[Sentry] \(error)")
        }
    )
}

extension AnalyticsClient {
    
    private static func configureMixpanel(id: String, isEnabled: Bool) {
        Mixpanel.initialize(
            token: Secrets.mixpanelToken,
            trackAutomaticEvents: true, // FIXME: LEGACY, REMOVE. https://docs.mixpanel.com/docs/tracking-methods/sdks/swift#legacy-automatically-tracked-events
            optOutTrackingByDefault: !isEnabled
        )
        
        @Dependency(\.analyticsClient) var analytics
        @Dependency(\.logger[.analytics]) var logger
        @Shared(.userSession) var userSession
        
        if let mixpanelUserId = Mixpanel.mainInstance().userId {
            if let userId = userSession?.userId {
                if String(userId) != mixpanelUserId {
                    logger.warning("Mixpanel user ID mismatch, changing to \(userId)")
                    analytics.identify(id: String(userId))
                } else {
                    logger.info("Analytics configured successfully")
                }
            } else {
                logger.warning("Mixpanel user ID found without user session, logging out")
                analytics.logout()
            }
        } else {
            logger.info("Mixpanel user ID not found, defaulting to \(id)")
            Mixpanel.mainInstance().distinctId = id
        }
    }
    
    private static func configureSentry(id: String, isEnabled: Bool, isDebugEnabled: Bool) {
        SentrySDK.start { options in
            options.dsn = Secrets.sentryDSN
            options.debug = isDebugEnabled
            options.enabled = isEnabled
            options.tracesSampleRate = 1.0
            options.profilesSampleRate = 1.0
            options.diagnosticLevel = .warning
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            options.swiftAsyncStacktraces = true
        }
        SentrySDK.setUser(User(userId: id))
    }
}

public enum AnalyticsError: Error {
    case brokenArticle(URL)
    case apiFailure(any Error)
}
