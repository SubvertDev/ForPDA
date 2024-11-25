//
//  AppEvent.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 25.11.2024.
//

import Foundation
import Models
import ComposableArchitecture

public enum AppEvent: Event {
    case firstTimeOpened
    case appUpdated(appVersion: String, buildVersion: String)
    
    public var name: String {
        switch self {
        case .firstTimeOpened:
            // Mimics legacy Mixpanel name
            return "$ae_first_open"
            
        case .appUpdated:
            // Mimics legacy Mixpanel name
            return "$ae_updated"
        }
    }
    
    public var properties: [String : String]? {
        switch self {
        case .firstTimeOpened:
            // Mimics legacy Mixpanel property + milliseconds timestamp type
            return ["$ae_first_app_open_date": String(Int(Date().timeIntervalSince1970 * 1000))]
            
        case let .appUpdated(appVersion, buildVersion):
            return [
                // Mimics legacy Mixpanel property
                "$ae_updated_version": String(appVersion),
                // Custom property
                "$ae_updated_build": String(buildVersion)
            ]
        }
    }
}
