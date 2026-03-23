//
//  BackgroundTheme.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.09.2024.
//

import Foundation

public enum BackgroundTheme: CaseIterable, Codable, Sendable {
    case blue
    case dark
    
    var _rawValue: String {
        switch self {
        case .blue: return "blue"
        case .dark: return "dark"
        }
    }
}
