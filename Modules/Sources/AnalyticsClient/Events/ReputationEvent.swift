//
//  ReputationEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 10.05.2026.
//

import Foundation

public enum ReputationEvent: Event {
    case pickerSectionChanged
    case loadMoreTapped
    case refreshTapped
    case profileTapped(Int)
    case complainTapped(Int)
    case sourceProfileTapped(Int)
    case sourceTopicTapped(Int)
    case sourceArticleTapped(Int)
    
    public var name: String {
        return "Reputation " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .profileTapped(profileId):
            return ["profileId": String(profileId)]
            
        case let .complainTapped(voteId):
            return ["voteId": String(voteId)]
            
        case let .sourceProfileTapped(profileId):
            return ["profileId": String(profileId)]
            
        case let .sourceTopicTapped(topicId):
            return ["topicId": String(topicId)]
            
        case let .sourceArticleTapped(articleId):
            return ["articleId": String(articleId)]
            
        default:
            return nil
        }
    }
}
