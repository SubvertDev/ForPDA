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
    
    public var text: LocalizedStringResource {
        switch self {
        case .first:  return .init("First page", bundle: .module)
        case .unread: return .init("Unread",     bundle: .module)
        case .last:   return .init("Last page",  bundle: .module)
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
