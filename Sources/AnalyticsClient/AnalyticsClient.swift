//
//  AnalyticsClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 24.03.2024.
//

import Foundation
import ComposableArchitecture
import Mixpanel
import Sentry
import OSLog

@DependencyClient
public struct AnalyticsClient: Sendable {
    public var configure: @Sendable () -> Void
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
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Analytics")
    
    public static var liveValue: Self {
        return AnalyticsClient(
            configure: {
                configureMixpanel()
                configureSentry()
            },
            log: { event in
                logger.info("\(event.name) | \(event.properties ?? [:])")
                Mixpanel.mainInstance().track(event: event.name, properties: event.properties)
            },
            capture: { error in
                logger.error("\(error) >>> \(error.localizedDescription)")
                SentrySDK.capture(error: error)
            }
        )
    }
    
    public static let previewValue = Self(
        configure: {},
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
    
    private static func configureMixpanel() {
        Mixpanel.initialize(
            token: Secrets.for(key: .MIXPANEL_TOKEN),
            trackAutomaticEvents: true, // FIXME: LEGACY, REMOVE. https://docs.mixpanel.com/docs/tracking-methods/sdks/swift#legacy-automatically-tracked-events
            optOutTrackingByDefault: isDebug
        )
    }
    
    private static func configureSentry() {
        SentrySDK.start { options in
            options.dsn = Secrets.for(key: .SENTRY_DSN)
            options.debug = isDebug
            options.enabled = !isDebug
            options.tracesSampleRate = 1.0
            options.diagnosticLevel = .warning
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            options.swiftAsyncStacktraces = true
        }
    }
}

public enum AnalyticsError: Error {
    case brokenArticle(URL)
    case apiFailure(any Error)
}

// TODO: Move to another place
private var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}

// FIXME: Find easier way to manage keys

private struct Secrets {
    
    enum Keys: String {
        case SENTRY_DSN
        case MIXPANEL_TOKEN
    }
    
    static func `for`(key: Keys) -> String {
        if let dictionary = Bundle.main.object(forInfoDictionaryKey: "SECRET_KEYS") as? [String: String] {
            return dictionary[key.rawValue] ?? ""
        } else {
            return ""
        }
    }
}
