//
//  BBAttributedToken.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 03.03.2025.
//

import Foundation

public enum BBToken: Equatable {
    case openingTag(BBTag, String?)
    case closingTag(BBTag)
    case text(String)
}

public extension BBToken {
    var description: String {
        switch self {
        case let .openingTag(tag, attribute):
            if let attribute {
                return "[\(tag)=\(attribute)]"
            } else {
                return "[\(tag)]"
            }
            
        case let .closingTag(tag):
            return "[/\(tag)]"
            
        case let .text(text):
            return text
        }
    }
    
    var tag: BBTag? {
        switch self {
        case .openingTag(let tag, _), .closingTag(let tag):
            return tag
        case .text:
            return nil
        }
    }
}
