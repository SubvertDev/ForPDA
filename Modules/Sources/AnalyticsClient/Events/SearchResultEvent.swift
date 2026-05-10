//
//  SearchResultEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 10.05.2026.
//

import Foundation

public enum SearchResultEvent: Event {
    case postTapped(Int, Int)
    case topicTapped(Int, Bool)
    case articleTapped(Int)
    
    public var name: String {
        return "Search Result " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .postTapped(topicId, postId):
            return [
                "topicId": String(topicId),
                "postId": String(postId)
            ]
            
        case let .topicTapped(id, isUnreadTapped):
            return [
                "id": String(id),
                "isUnreadTapped": String(isUnreadTapped)
            ]
            
        case let .articleTapped(id):
            return ["id": String(id)]
        }
    }
}
