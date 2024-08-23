//
//  MenuEvent.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum MenuEvent: Event {
    case authTapped
    case profileTapped
    case settingsTapped
    case author4PDATapped
    case changelogTelegramTapped
    case chatTelegramTapped
    case githubTapped
    case _userSessionUpdated(Int?)
    
    public var name: String {
        return "Menu " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let ._userSessionUpdated(userId):
            if let userId {
                return ["userId": String(userId)]
            } else {
                return ["userId": "none"]
            }

        default:
            return nil
        }
    }
}
