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
    case clearCacheTapped
    case checkVersionsTapped
    case _somethingWentWrong(any Error)
    
    public var name: String {
        return "Settings " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let ._somethingWentWrong(error):
            return ["error": error.localizedDescription]
        default:
            return nil
        }
    }
}
