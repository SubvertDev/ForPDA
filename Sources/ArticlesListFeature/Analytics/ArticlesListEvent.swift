//
//  ArticlesListEvent.swift
//
//
//  Created by Ilia Lubianoi on 19.05.2024.
//

import Foundation
import AnalyticsClient

public enum ArticlesListEvent: Event {
    #warning("Сделать url специально для Event?")
    case articleTapped(Int)
    case linkCopied(URL)
    case linkShared(URL)
    case linkReported(URL)
    case refreshTriggered
    case loadMoreTriggered
    case menuTapped
    case vpnWarningShown
    case vpnWarningAction(WarningAction)
    
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
            
        case .vpnWarningAction(let action):
            return ["action": action.rawValue]
            
        default:
            return nil
        }
    }
    
    public enum WarningAction: String {
        case openCaptcha = "open_captcha"
        case cancel
    }
}
