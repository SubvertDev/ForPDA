//
//  TopicEvent.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import Foundation

public enum TopicEvent: Event {
    case onRefresh
    case topicHatButtonTapped
    case topicPollOpenButtonTapped
    case userTapped(Int)
    case urlTapped(URL)
    case imageTapped(URL)
    case editWarningSheetClosed
    
    case menuCopyLink
    case menuOpenInBrowser
    case menuGoToEnd
    case menuSetFavorite
    case menuWritePost
    
    case menuPostReply(Int)
    case menuPostKarma(Int)
    case menuPostEdit(Int)
    case menuPostDelete(Int)
    case menuPostReport(Int)
    case menuChangeReputation(Int, Int)
    case menuPostCopyLink(Int)
    
    public var name: String {
        return "Topic " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .userTapped(id),
             let .menuPostReply(id):
            return ["userId": String(id)]
            
        case let .menuPostDelete(postId),
             let .menuPostKarma(postId),
             let .menuPostReport(postId),
             let .menuPostCopyLink(postId):
            return ["postId": String(postId)]
            
        case let .menuChangeReputation(postId, userId):
            return ["postId": String(postId), "userId": String(userId)]
            
        case let .urlTapped(url),
             let .imageTapped(url):
            return ["url": url.absoluteString]
            
        default:
            return nil
        }
    }
}
