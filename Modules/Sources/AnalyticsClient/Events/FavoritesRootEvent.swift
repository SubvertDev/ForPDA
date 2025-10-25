//
//  FavoritesRootEvent.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import Foundation

public enum FavoritesRootEvent: Event {
    case tabChanged(Int)
    
    public var name: String {
        return "Favorites Root " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .tabChanged(tab):
            return ["tab": String(tab)]
        }
    }
}
