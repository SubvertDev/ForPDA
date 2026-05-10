//
//  QMSListEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 10.05.2026.
//

import Foundation

public enum QMSListEvent: Event {
    case chatTapped(Int)
    case userTapped(Int, isExpandable: Bool)
    
    public var name: String {
        return "QMS List " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .chatTapped(chatId):
            return ["chatId": String(chatId)]
            
        case let .userTapped(userId, isExpandable):
            return [
                "userId": String(userId),
                "isExpandable": String(isExpandable)
            ]
        }
    }
}
