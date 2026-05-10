//
//  MoreEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 10.05.2026.
//

import Foundation

public enum MoreEvent: Event {
    case profileTapped(Bool)
    case qmsTapped
    case mentionsTapped
    case historyTapped
    case settingsTapped
    case supportOnBoostyTapped
    case appDiscussionTapped
    case telegramChatTapped
    case githubTapped
    case logoutTapped
    case logoutConfirmed
    
    public var name: String {
        return "More " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .profileTapped(isLoggedIn):
            return ["isLoggedIn": String(isLoggedIn)]
            
        default:
            return nil
        }
    }
}
