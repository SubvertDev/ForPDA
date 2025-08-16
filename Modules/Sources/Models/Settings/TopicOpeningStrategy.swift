//
//  TopicOpeningStrategy.swift
//  Models
//
//  Created by Ilia Lubianoi on 16.08.2025.
//

import SwiftUI

public enum TopicOpeningStrategy: CaseIterable, Codable, Sendable {
    case first
    case unread
    case last
    
    public var title: LocalizedStringKey {
        switch self {
        case .first:
            return "First page"
        case .unread:
            return "Unread"
        case .last:
            return "Last page"
        }
    }
    
    public var asGoTo: GoTo {
        switch self {
        case .first:  return .first
        case .unread: return .unread
        case .last:   return .last
        }
    }
}
