//
//  ArticleEvent.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum ArticleEvent: Event {
    case onRefresh
    case backButtonTapped
    case linkCopied(URL)
    case linkShareOpened(URL)
    case linkShared(Bool, URL)
    case linkReported(URL)
    case inlineLinkTapped(URL) // TODO: Rename from inline to TCA action name?
    case inlineButtonTapped(URL)
    case bookmarkButtonTapped(URL)
    case commentLiked(Int)
    case removeReplyCommentTapped
    case sendCommentTapped
    case pollVoteTapped
    case loadingSuccess
    case loadingFailure(any Error)
    case parsingFailure(any Error)
    // TODO: Comments
    
    public var name: String {
        return "Article " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .linkCopied(url),
             let .linkShareOpened(url),
             let .linkReported(url),
             let .inlineLinkTapped(url),
             let .inlineButtonTapped(url),
             let .bookmarkButtonTapped(url):
            return ["url": url.absoluteString]
            
        case let .linkShared(success, url):
            return ["url": url.absoluteString, "success": String(success)]
            
        case .loadingFailure(let error),
             .parsingFailure(let error):
            return ["reason": error.localizedDescription]
            
        case let .commentLiked(id):
            return ["id": String(id)]
            
        default:
            return nil
        }
    }
}
