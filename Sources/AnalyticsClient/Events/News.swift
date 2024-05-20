//
//  News.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum NewsEvent: Event {
    case closed
    case linkCopied(URL)
    case linkShared(URL)
    case linkReported(URL)
    case inlineLinkTapped(URL)
    case inlineButtonTapped(URL)
    // RELEASE: Add comments?
    
    public var name: String {
        return "News " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case .linkCopied(let url),
             .linkShared(let url),
             .linkReported(let url),
             .inlineLinkTapped(let url),
             .inlineButtonTapped(let url):
            return ["url": url.absoluteString]
        default:
            return nil
        }
    }
}
