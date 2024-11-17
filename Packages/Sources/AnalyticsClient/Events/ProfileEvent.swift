//
//  ProfileEvent.swift
//  
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum ProfileEvent: Event {
    case settingsTapped
    case logoutTapped
    case historyTapped
    case userLoaded(Int)
    case userLoadingFailed
    
    public var name: String {
        return "Profile " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .userLoaded(userId):
            return ["userId": String(userId)]
        default:
            return nil
        }
    }
}
