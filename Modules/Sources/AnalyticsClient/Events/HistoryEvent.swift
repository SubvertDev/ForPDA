//
//  HistoryEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 10.05.2026.
//

import Foundation

public enum HistoryEvent: Event {
    case topicTapped(Int, String, Bool)
    
    public var name: String {
        return "History " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .topicTapped(id, name, showUnread):
            return [
                "id": String(id),
                "name": name,
                "show_unread": String(showUnread)
            ]
        }
    }
}
