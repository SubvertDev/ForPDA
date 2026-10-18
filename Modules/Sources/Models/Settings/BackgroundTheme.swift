//
//  BackgroundTheme.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.09.2024.
//

import Foundation

public enum BackgroundTheme: CaseIterable, Codable, Sendable {
    case blue
    case black
    
    var _rawValue: String {
        switch self {
        case .blue: return "blue"
        case .black: return "black"
        }
    }
}
