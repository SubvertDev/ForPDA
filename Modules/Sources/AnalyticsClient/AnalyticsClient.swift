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
    
    struct Secrets {
        enum Key: String {
            case SENTRY_DSN
            case SENTRY_DSYM_TOKEN
            case POSTHOG_TOKEN
        }
        
        static func get(_ key: Key) -> String {
            guard let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String
            else { fatalError("Couldn't find \(key.rawValue) key") }
            return value
        }
    }
    
    private static func configureAnalytics(id: String, isEnabled: Bool, isDebugEnabled: Bool) {
        let config = PostHogConfig(apiKey: Secrets.get(.POSTHOG_TOKEN), host: "https://eu.i.posthog.com")
        config.debug = isDebugEnabled
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
            options.dsn = Secrets.get(.SENTRY_DSN)
            options.debug = isDebugEnabled
            options.enabled = isEnabled
            options.enableAppLaunchProfiling = true
            options.enableMetricKit = true
            options.enableAppHangTrackingV2 = true
            options.enablePerformanceV2 = true
            options.enablePreWarmedAppStartTracing = true
            options.enableCoreDataTracing = false // I don't have CoreData
            options.enableUserInteractionTracing = false // Doesn't work with SwiftUI
            options.enableUIViewControllerTracing = false // I dont' have UIViewControllers
            options.tracePropagationTargets = ["4pda"] // Dismiss analytics requests
            options.swiftAsyncStacktraces = true
            options.attachScreenshot = true
            options.tracesSampleRate = 1.0
            options.diagnosticLevel = .warning
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

// TODO: Took out from posthog, not public anymore for some reason
extension UUID {
    static func v7() -> Self {
        TimeBasedEpochGenerator.shared.v7()
    }
}

final class TimeBasedEpochGenerator {
    nonisolated(unsafe) static let shared = TimeBasedEpochGenerator()

    // Private initializer to prevent multiple instances
    private init() {}

    private var lastEntropy = [UInt8](repeating: 0, count: 10)
    private var lastTimestamp: UInt64 = 0

    private let lock = NSLock()

    func v7() -> UUID {
        var uuid: UUID?

        lock.withLock {
            uuid = generateUUID()
        }

        // or fallback to UUID v4
        return uuid ?? UUID()
    }

    private func generateUUID() -> UUID? {
        let timestamp = Date().timeIntervalSince1970
        let unixTimeMilliseconds = UInt64(timestamp * 1000)

        var uuidBytes = [UInt8]()

        let timeBytes = unixTimeMilliseconds.bigEndianData.suffix(6) // First 6 bytes for the timestamp
        uuidBytes.append(contentsOf: timeBytes)

        if unixTimeMilliseconds == lastTimestamp {
            var check = true
            for index in (0 ..< 10).reversed() where check {
                var temp = lastEntropy[index]
                temp = temp &+ 0x01
                check = lastEntropy[index] == 0xFF
                lastEntropy[index] = temp
            }
        } else {
            lastTimestamp = unixTimeMilliseconds

            // Prepare the random part (10 bytes to complete the UUID)
            let status = SecRandomCopyBytes(kSecRandomDefault, lastEntropy.count, &lastEntropy)
            // If we can't generate secure random bytes, use a fallback
            if status != errSecSuccess {
                let randomData = (0 ..< 10).map { _ in UInt8.random(in: 0 ... 255) }
                lastEntropy = randomData
            }
        }
        uuidBytes.append(contentsOf: lastEntropy)

        // Set version (7) in the version byte
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x70

        // Set the UUID variant (10xx for standard UUIDs)
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80

        // Ensure we have a total of 16 bytes
        if uuidBytes.count == 16 {
            return UUID(uuid: (uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
                               uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
                               uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
                               uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]))
        }

        return nil
    }
}

extension UInt64 {
    // Correctly generate Data representation in big endian format
    var bigEndianData: Data {
        var bigEndianValue = bigEndian
        return Data(bytes: &bigEndianValue, count: MemoryLayout<UInt64>.size)
    }
}
