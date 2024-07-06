//
//  ArticlesListEvent.swift
//
//
//  Created by Ilia Lubianoi on 19.05.2024.
//

import Foundation

public enum ArticlesListEvent: Event {
    // TODO: Add URL to Int?
    case articleTapped(Int)
    case linkCopied(URL)
    case linkShared(URL)
    case linkReported(URL)
    case refreshTriggered
    case loadMoreTriggered
    case menuTapped
    case articlesHasLoaded // TODO: Rename?
    case articlesHasNotLoaded(String)
    case failedToConnect
    
    public var name: String {
        return "Articles List " + eventName(for: self)
    }
    
    public var properties: [String: String]? {
        switch self {
        case .articleTapped(let id):
            return ["id": String(id)]
            
        case .linkCopied(let url),
             .linkShared(let url),
             .linkReported(let url):
            return ["url": url.absoluteString]
            
        case .articlesHasNotLoaded(let errorMessage):
            return ["error": errorMessage]
            
        default:
            return nil
        }
    }
}
