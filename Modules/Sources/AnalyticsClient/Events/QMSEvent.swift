//
//  QMSEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 10.05.2026.
//

import Foundation

public enum QMSEvent: Event {
    case sendMessageTapped(isEmpty: Bool)
    case loadMoreTriggered
    case linkTapped(URL)
    
    public var name: String {
        return "QMS " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .sendMessageTapped(isEmpty):
            return ["isEmpty": String(isEmpty)]
            
        case let .linkTapped(url):
            return ["url": url.absoluteString]
            
        default:
            return nil
        }
    }
}
