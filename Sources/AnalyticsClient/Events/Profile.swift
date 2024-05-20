//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum ProfileEvent: Event {
    case closed
    case logoutTapped
    
    public var name: String {
        return "Profile " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        default:
            return nil
        }
    }
}
