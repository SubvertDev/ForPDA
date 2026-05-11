//
//  DeviceSpecificationsEvent.swift
//  AnalyticsClient
//
//  Created by Codex on 11.05.2026.
//

import Foundation

public enum DeviceSpecificationsEvent: Event {
    case linkCopied(String)
    case headerImageTapped(Int)
    case editionTapped(String)
    case markAsMyDeviceTapped(Bool)
    case longEntryTapped(String)
    case longEntryCloseTapped
    
    public var name: String {
        return "Device Specifications " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .linkCopied(url):
            return ["url": url]
            
        case let .headerImageTapped(id):
            return ["id": String(id)]
            
        case let .editionTapped(subTag):
            return ["subTag": subTag]
            
        case let .markAsMyDeviceTapped(isMyDevice):
            return ["isMyDevice": String(isMyDevice)]
            
        case let .longEntryTapped(name):
            return ["name": name]
            
        case .longEntryCloseTapped:
            return nil
        }
    }
}
