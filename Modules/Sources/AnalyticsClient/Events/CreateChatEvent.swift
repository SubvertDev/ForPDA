//
//  QMSListEvent 2.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 30.05.2026.
//

public enum CreateChatEvent: Event {
    case searchUserSelected
    case sendTapped
    case closeTapped
    
    public var name: String {
        return "Create Chat " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        return nil
    }
}
