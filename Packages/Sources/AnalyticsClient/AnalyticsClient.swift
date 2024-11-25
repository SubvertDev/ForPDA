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
                @Shared(.appStorage(AppStorageKeys.analyticsId)) var analyticsId = UUID().uuidString
                
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
        Mixpanel.initialize(
            token: Secrets.mixpanelToken,
            trackAutomaticEvents: false,
            useUniqueDistinctId: false
        )
        
        Mixpanel.mainInstance().loggingEnabled = isDebugEnabled
        
        // Checking for opt out
        let isOptedOut = Mixpanel.mainInstance().hasOptedOutTracking()
        if isEnabled && isOptedOut {
            Mixpanel.mainInstance().optInTracking(distinctId: id, properties: nil)
        } else if !isEnabled && !isOptedOut {
            Mixpanel.mainInstance().optOutTracking()
        }
        
        @Dependency(\.analyticsClient) var analytics
        @Dependency(\.logger[.analytics]) var logger
        @Shared(.userSession) var userSession
        
        // Check if we have a current user session and id
        if let userId = userSession?.userId {
            // Check if user ID is the same as Mixpanel ID
            if String(userId) == Mixpanel.mainInstance().userId {
                // If there's no mismatch, we're configured
                logger.info("Analytics has been succesfully configured. Enabled: \(isEnabled) / Debug: \(isDebugEnabled)")
            } else {
                // If there's mismatch, we're doomed (jk)
                logger.warning("Mixpanel user ID & user session ID mismatch, identifying as \(userId)")
                analytics.identify(String(userId))
            }
        } else {
            logger.info("User session not found, defaulting Mixpanel ID to \(id)")
            Mixpanel.mainInstance().distinctId = id
        }
        
        let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let currentAppBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        
        // Check if we're opening the app for the first time
        @Shared(.appStorage(AppStorageKeys.firstTimeOpened)) var firstTimeOpened: Bool = false
        if !firstTimeOpened && !didOpenForFirstTimeInMixpanel() {
            firstTimeOpened = true
            analytics.log(AppEvent.firstTimeOpened)
        }
        
        // Check if we've updated the app since last open
        @Shared(.appStorage(AppStorageKeys.lastAppVersion)) var lastAppVersion: String?
        @Shared(.appStorage(AppStorageKeys.lastAppBuild)) var lastAppBuild: String?
        if currentAppVersion != lastAppVersion || currentAppBuild != lastAppBuild {
            lastAppVersion = currentAppVersion
            lastAppBuild = currentAppBuild
            analytics.log(AppEvent.appUpdated(appVersion: currentAppVersion, buildVersion: currentAppBuild))
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

// MARK: - Extensions

extension AnalyticsClient {
    // For backward compatibility to now spawn lots of first opens after disabling legacy automatic events
    private static func didOpenForFirstTimeInMixpanel() -> Bool {
        if let preferencesPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Preferences/Mixpanel.plist") {
            if let data = try? Data(contentsOf: preferencesPath) {
                if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                    for (key, value) in plist where key.contains("MPFirstOpen") {
                        return value as? Bool ?? false
                    }
                }
            }
        }
        return false
    }
}

public extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}
