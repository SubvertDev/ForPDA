//
//  Menu.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum MenuEvent: Event {
    case closed
    case loginTapped
    case profileTapped
    case historyTapped
    case bookmarksTapped
    case settingsTapped
    case author4PDATapped
    case discussion4PDATapped
    case changelogTelegramTapped
    case chatTelegramTapped
    case githubTapped
    
    public var name: String {
        return "Menu " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String] {
        switch self {
        default:
            return [:]
        }
    }
}
