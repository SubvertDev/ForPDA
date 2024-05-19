//
//  NewsListEvent.swift
//
//
//  Created by Ilia Lubianoi on 19.05.2024.
//

import Foundation
import AnalyticsClient

public enum NewsListEvent: Event {
    case newsTapped(URL)
    case linkCopied(URL)
    case linkShared(URL)
    case linkReported(URL)
    case refreshTriggered
    case menuTapped
    case vpnWarningShown
    case vpnWarningAction(WarningAction)
    
    public var name: String {
        return "News List " + eventName(for: self)
    }
    
    public var properties: [String: String] {
        switch self {
        case .newsTapped(let url),
             .linkCopied(let url),
             .linkShared(let url),
             .linkReported(let url):
            return ["url": url.absoluteString]
        case .vpnWarningAction(let action):
            return ["action": action.rawValue]
        default:
            return [:]
        }
    }
    
    public enum WarningAction: String {
        case openCaptcha = "open_captcha"
        case cancel
    }
}
