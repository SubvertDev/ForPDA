//
//  ArticleEvent.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum ArticleEvent: Event {
    // case opened // ?
    case closed // TODO: Do I need this?
    case linkCopied(URL)
    case linkShared(URL)
    case linkReported(URL)
    case inlineLinkTapped(URL) // TODO: Rename from inline to TCA action name?
    case inlineButtonTapped(URL)
    case loadingSuccess
    case loadingFailure(Error)
    case parsingFailure(Error)
    // TODO: Comments
    
    public var name: String {
        return "Article " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case .linkCopied(let url),
             .linkShared(let url),
             .linkReported(let url),
             .inlineLinkTapped(let url),
             .inlineButtonTapped(let url):
            return ["url": url.absoluteString]
            
        case .loadingFailure(let error),
             .parsingFailure(let error):
            return ["reason": error.localizedDescription]
            
        default:
            return nil
        }
    }
}
