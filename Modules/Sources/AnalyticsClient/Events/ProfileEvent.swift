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
    case mentionsTapped
    case reputationTapped
    case searchTopicsTapped
    case searchRepliesTapped
    case deviceButtonTapped(String)
    case userLoaded(Int)
    case userLoadingFailed
    case achievementTapped
    case linkInAboutTapped
    case linkInSignatureTapped
    case linkInWarningLogTapped
    case curatedTopicTapped(Int)
    
    public var name: String {
        return "Profile " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .userLoaded(userId):
            return ["userId": String(userId)]
        case let .deviceButtonTapped(tag):
            return ["deviceTag": tag]
        case let .curatedTopicTapped(topicId):
            return ["topicId": String(topicId)]
        default:
            return nil
        }
    }
}
