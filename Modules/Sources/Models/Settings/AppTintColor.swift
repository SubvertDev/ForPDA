//
//  AppTintColor.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.09.2024.
//

import Foundation

public enum AppTintColor: CaseIterable, Codable, Sendable {
    case lettuce
    case orange
    case pink
    case primary
    case purple
    case scarlet
    case sky
    case yellow
    
    var _rawValue: String {
        switch self {
        case .lettuce: "lettuce"
        case .orange:  "orange"
        case .pink:    "pink"
        case .primary: "primary"
        case .purple:  "purple"
        case .scarlet: "scarlet"
        case .sky:     "sky"
        case .yellow:  "yellow"
        }
    }
}
