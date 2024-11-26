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
import PostHog
import Sentry
import OSLog

// MARK: - Client

@DependencyClient
public struct AnalyticsClient: Sendable {
    public var configure: @Sendable (AnalyticsConfiguration) -> Void
    public var identify: @Sendable (_ id: String) -> Void
    public var logout: @Sendable () -> Void
    public var log: @Sendable (any Event) -> Void
    public var capture: @Sendable (any Error) -> Void
}

// MARK: - Dependency Keys

extension AnalyticsClient: DependencyKey {
    
    public static var liveValue: Self {
        @Dependency(\.logger[.analytics]) var logger
        
        return AnalyticsClient(
            configure: { config in
                @Shared(.appStorage(AppStorageKeys.analyticsId)) var analyticsId = UUID.v7().uuidString
                
                configureAnalytics(
                    id: analyticsId,
                    isEnabled: config.isAnalyticsEnabled,
                    isDebugEnabled: config.isAnalyticsDebugEnabled
                )
                
                configureCrashlytics(
                    id: analyticsId,
                    isEnabled: config.isCrashlyticsEnabled,
                    isDebugEnabled: config.isCrashlyticsDebugEnabled
                )
            },
            identify: { id in
                logger.info("Identifying user with id: \(id)")
                PostHogSDK.shared.identify(id)
            },
            logout: {
                logger.info("Analytics has been reset after logout")
                PostHogSDK.shared.reset()
            },
            log: { event in
                logger.info("\(event.name) \(event.properties.map { "(\($0))" } ?? "")")
                PostHogSDK.shared.capture(event.name, properties: event.properties)
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
        logout: { },
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
    
    public static let testValue = Self(
        configure: { _ in },
        identify: { _ in },
        logout: { },
        log: { _ in },
        capture: { _ in }
    )
}

// MARK: - Configurations

extension AnalyticsClient {
    
    private static func configureAnalytics(id: String, isEnabled: Bool, isDebugEnabled: Bool) {
        let config = PostHogConfig(apiKey: Secrets.posthogToken, host: "https://eu.i.posthog.com")
        config.debug = true
        config.getAnonymousId = { _ in UUID(uuidString: id) ?? UUID.v7() }
        config.optOut = !isEnabled
        config.captureScreenViews = false // Track manually
        PostHogSDK.shared.setup(config)
        
        // Checking for opt out
        let isPosthogOptedOut = PostHogSDK.shared.isOptOut()
        if isEnabled && isPosthogOptedOut {
            PostHogSDK.shared.optIn()
        } else if !isEnabled && !isPosthogOptedOut {
            PostHogSDK.shared.optOut()
        }
        
        @Dependency(\.analyticsClient) var analytics
        @Dependency(\.logger[.analytics]) var logger
        @Shared(.userSession) var userSession
        
        // Check if we have a current user session and id
        if let userId = userSession?.userId {
            // Check if user ID is the same as PostHog ID
            if String(userId) == PostHogSDK.shared.getDistinctId() {
                // If there's no mismatch, we're configured
                logger.info("Analytics has been succesfully configured. Enabled: \(isEnabled) / Debug: \(isDebugEnabled)")
            } else {
                // If there's mismatch, we're doomed (jk)
                logger.warning("Analytics user ID & user session ID mismatch, identifying as \(userId)")
                analytics.identify(String(userId))
            }
        } else {
            logger.info("User session not found, using default analytics ID: \(id)")
        }
    }
    
    private static func configureCrashlytics(id: String, isEnabled: Bool, isDebugEnabled: Bool) {
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
        
        @Dependency(\.logger[.analytics]) var logger
        logger.info("Crashlytics has been successfully configured. Enabled: \(isEnabled) / Debug: \(isDebugEnabled)")
    }
}

// MARK: - Extension

public extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}
