//
//  QMSListEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 10.05.2026.
//

import Foundation

public enum QMSListEvent: Event {
    case onRefresh
    case chatTapped
    case userTapped(isExpandable: Bool)
    case createChatInUserTapped
    case createChatInRowTapped
    case tryAgainTapped
    case deleteChatTapped
    case deleteChatConfirmed
    case deleteAllChatsTapped
    case deleteAllChatsConfirmed
    
    public var name: String {
        return "QMS List " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .userTapped(isExpandable):
            return ["isExpandable": String(isExpandable)]
            
        default:
            return nil
        }
    }
}
