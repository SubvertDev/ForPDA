//
//  CommentEvent.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 22.11.2024.
//

import Foundation

public enum CommentEvent: Event {
    case profileTapped
    case hiddenLabelTapped
    case reportButtonTapped
    case hideButtonTapped
    case replyButtonTapped
    case likeButtonTapped
    case changeReputationButtonTapped
    
    public var name: String {
        return "Comment " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        default:
            return nil
        }
    }
}
