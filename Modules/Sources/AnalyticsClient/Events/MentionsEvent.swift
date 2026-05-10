//
//  MentionsEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 10.05.2026.
//

import Foundation

public enum MentionsEvent: Event {
    case mentionTapped(sourceId: Int, targetId: Int, sourceName: String, type: String)
    
    public var name: String {
        return "Mentions " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .mentionTapped(sourceId, targetId, sourceName, type):
            return [
                "sourceId": String(sourceId),
                "targetId": String(targetId),
                "sourceName": sourceName,
                "type": type
            ]
        }
    }
}
