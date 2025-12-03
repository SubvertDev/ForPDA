//
//  ForumsListEvent.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import Foundation

public enum ForumsListEvent: Event {
    case forumRedirectTapped(URL)
    case forumTapped(Int, String)
    case forumSearchTapped
    case forumListLoadSuccess
    case forumListLoadFailure(any Error)
    case forumSectionExpanded(Int)
    
    public var name: String {
        return "Forums List " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .forumRedirectTapped(url):
            return ["url": url.absoluteString]
            
        case let .forumTapped(id, name):
            return ["id": String(id), "name": name]
            
        default:
            return nil
        }
    }
}
