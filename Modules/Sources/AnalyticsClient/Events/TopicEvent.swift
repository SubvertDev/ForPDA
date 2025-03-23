//
//  TopicEvent.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import Foundation

public enum TopicEvent: Event {
    case onRefresh
    case userAvatarTapped(Int)
    case urlTapped(URL)
    
    case menuCopyLink
    case menuOpenInBrowser
    case menuGoToEnd
    case menuSetFavorite
    
    case loadingStart(Int)
    case loadingSuccess
    case loadingFailure(any Error)
    case setFavoriteResponse(Bool)
    
    public var name: String {
        return "Topic " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .userAvatarTapped(id):
            return ["userId": String(id)]
            
        case let .urlTapped(url):
            return ["url": url.absoluteString]
            
        case let .loadingStart(offset):
            return ["offset": String(offset)]
            
        case let .loadingFailure(error):
            return ["error": error.localizedDescription]
            
        case let .setFavoriteResponse(state):
            return ["state": state.description]
            
        default:
            return nil
        }
    }
}
