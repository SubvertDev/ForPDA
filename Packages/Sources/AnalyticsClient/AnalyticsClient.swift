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
                @Shared(.appStorage("analytics_id")) var analyticsId = UUID().uuidString
                configureMixpanel(id: analyticsId)
                configureSentry(id: analyticsId)
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
    
    private static func configureMixpanel(id: String) {
        Mixpanel.initialize(
            token: Secrets.mixpanelToken,
            trackAutomaticEvents: true, // FIXME: LEGACY, REMOVE. https://docs.mixpanel.com/docs/tracking-methods/sdks/swift#legacy-automatically-tracked-events
            optOutTrackingByDefault: isDebug
        )
        Mixpanel.mainInstance().userId = id
    }
    
    private static func configureSentry(id: String) {
        SentrySDK.start { options in
            options.dsn = Secrets.sentryDSN
            options.debug = isDebug
            options.enabled = !isDebug
            options.tracesSampleRate = 1.0
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

// TODO: Move to another place
private var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}
