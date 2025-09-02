//
//  TopicEvent.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import Foundation

public enum TopicEvent: Event {
    case onRefresh
    case topicHatOpenButtonTapped
    case userTapped(Int)
    case urlTapped(URL)
    case imageTapped(URL)
    case editWarningSheetClosed
    
    case menuCopyLink
    case menuOpenInBrowser
    case menuGoToEnd
    case menuSetFavorite
    case menuWritePost
    case menuWritePostWithTemplate
    
    case menuPostReply(Int)
    case menuPostKarma(Int)
    case menuPostEdit(Int)
    case menuPostDelete(Int)
    case menuPostReport(Int)
    case menuChangeReputation(Int, Int)
    
    case loadingStart(Int)
    case loadingSuccess
    case loadingFailure(any Error)
    case setFavoriteResponse(Bool)
    
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
             let .menuPostReport(postId):
            return ["postId": String(postId)]
            
        case let .menuChangeReputation(postId, userId):
            return ["postId": String(postId), "userId": String(userId)]
            
        case let .urlTapped(url),
             let .imageTapped(url):
            return ["url": url.absoluteString]
            
        case let .loadingStart(offset):
            return ["offset": String(offset)]
            
        case let .loadingFailure(error):
            return ["error": error.localizedDescription]
            
        case let .setFavoriteResponse(state):
            return ["state": state.description]
            
        default:
            return nil
        }
    }
}
