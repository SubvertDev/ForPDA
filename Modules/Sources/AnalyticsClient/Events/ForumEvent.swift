//
//  ForumEvent.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import Foundation

public enum ForumEvent: Event {
    case onRefresh
    case settingsButtonTapped
    case topicTapped(Int, Int)
    case subforumRedirectTapped(URL)
    case subforumTapped(Int, String)
    case announcementTapped(Int, String)
    
    // case menuSort
    // case menuBookmarks
    
    case menuOpen(Int)
    case menuGoToEnd(Int)
    
    case menuMarkRead(Int, Bool)
    case menuCopyLink(Int, Bool)
    case menuOpenInBrowser(Int, Bool)
    case menuSetFavorite(Int, Bool, Bool)
    
    case loadingStart(Int)
    case loadingSuccess
    case loadingFailure(any Error)
    
    public var name: String {
        return "Forum " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .topicTapped(id, offset):
            return ["id": String(id), "offset": String(offset)]
            
        case let .subforumRedirectTapped(url):
            return ["url": url.absoluteString]
            
        case let .subforumTapped(id, name):
            return ["id": String(id), "name": name]
            
        case let .announcementTapped(id, name):
            return ["id": String(id), "name": name]
            
        case let .menuOpen(id):
            return ["id": String(id)]
            
        case let .menuGoToEnd(id):
            return ["id": String(id)]
            
        case let .menuMarkRead(id, isForum):
            return ["id": String(id), "isForum": String(isForum)]
            
        case let .menuCopyLink(id, isForum):
            return ["id": String(id), "isForum": String(isForum)]
            
        case let .menuOpenInBrowser(id, isForum):
            return ["id": String(id), "isForum": String(isForum)]
            
        case let .menuSetFavorite(id, isForum, state):
            return ["id": String(id), "isForum": String(isForum), "state": state.description]
            
        case let .loadingStart(offset):
            return ["offset": String(offset)]
            
        case let .loadingFailure(error):
            return ["error": error.localizedDescription]
            
        default:
            return nil
        }
    }
}
