//
//  AppColorScheme.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.09.2024.
//

import SwiftUI

public enum AppColorScheme: CaseIterable, Codable, Sendable {
    
    case light
    case dark
    case system
    
    var _rawValue: String {
        switch self {
        case .light:  return "light"
        case .dark:   return "dark"
        case .system: return "system"
        }
    }
    
    public var asColorScheme: ColorScheme? {
        switch self {
        case .light:    ColorScheme.light
        case .dark:     ColorScheme.dark
        case .system:   ColorScheme(.unspecified)
        }
    }
}
