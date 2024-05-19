//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum SettingsEvent: Event {
    case closed
    case languageTapped
    case themeTapped
    case themeAction(ThemeAction)
    case nightModeBackgroundColorTapped
    case nightModeBackgroundColorAction(NightModeBackgroundColorAction)
    case safariExtensionsTapped
    case fastLoadingSystemAction(ToggleAction)
    case showLikesInCommentsAction(ToggleAction)
    case githubRepositoryTapped
    
    public var name: String {
        return "Settings " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String] {
        switch self {
        case .themeAction(let action):
            return ["action": action.rawValue]
        case .nightModeBackgroundColorAction(let action):
            return ["action": action.rawValue]
        case .fastLoadingSystemAction(let action), 
             .showLikesInCommentsAction(let action):
            return ["action": action.rawValue]
        default:
            return [:]
        }
    }
}

public enum ThemeAction: String {
    case auto
    case light
    case dark
    case cancel
}

public enum NightModeBackgroundColorAction: String {
    case dark
    case black
}

public enum ToggleAction: String {
    case on
    case off
}
