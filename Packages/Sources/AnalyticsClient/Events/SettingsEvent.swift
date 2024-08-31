//
//  SettingsEvent.swift
//  
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum SettingsEvent: Event {
    case languageTapped
    case themeTapped
    case safariExtensionTapped
    case copyDebugIdTapped
    case clearCacheTapped
    case checkVersionsTapped
    case somethingWentWrong(any Error)
    
    public var name: String {
        return "Settings " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .somethingWentWrong(error):
            return ["error": error.localizedDescription]
        default:
            return nil
        }
    }
}
