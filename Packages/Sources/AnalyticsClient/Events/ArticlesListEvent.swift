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
    case linkShareOpened(URL)
    case linkShared(Bool, URL)
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
             .linkShareOpened(let url),
             .linkReported(let url):
            return ["url": url.absoluteString]
            
        case let .linkShared(success, url):
            return ["url": url.absoluteString, "success": String(success)]
            
        case .articlesHasNotLoaded(let errorMessage):
            return ["error": errorMessage]
            
        default:
            return nil
        }
    }
}
