//
//  ProfileEvent.swift
//  
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum ProfileEvent: Event {
    case qmsTapped
    case editTapped
    case settingsTapped
    case logoutTapped
    case historyTapped
    case reputationTapped
    case searchTopicsTapped
    case searchRepliesTapped
    case userLoaded(Int)
    case userLoadingFailed
    case achievementTapped
    case linkInAboutTapped
    case linkInSignatureTapped
    
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
