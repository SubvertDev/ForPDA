//
//  AppDelegateFeature.swift
//
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import ComposableArchitecture
import Mixpanel
import Sentry
import Nuke

@Reducer
public struct AppDelegateFeature {
    
    public init() {}
    
    // MARK: - State
    
    public struct State: Equatable {
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        case didFinishLaunching
    }
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didFinishLaunching:
                
                // Configuring Mixpanel
                Mixpanel.initialize(
                    token: Secrets.for(key: .MIXPANEL_TOKEN),
                    trackAutomaticEvents: true
                )
                
                // Configuring Sentry
                SentrySDK.start { options in
                    options.dsn = Secrets.for(key: .SENTRY_DSN)
                    options.debug = isDebug
                    options.enabled = !isDebug
                    options.tracesSampleRate = 1.0
                    options.diagnosticLevel = .warning
                    options.attachScreenshot = true
                }
                
                // Configuring Nuke
                ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
                
                return .none
            }
        }
    }
}

// MARK: - Helpers

private var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}

struct Secrets {
    
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
