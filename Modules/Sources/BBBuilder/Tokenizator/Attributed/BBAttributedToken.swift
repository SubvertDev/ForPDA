//
//  BBAttributedToken.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.03.2025.
//

import Foundation

public enum BBAttributedToken: Equatable {
    case openingTag(BBTag, AttributedString?)
    case closingTag(BBTag)
    case text(AttributedString)
}

public extension BBAttributedToken {
    var description: AttributedString {
        switch self {
        case let .openingTag(tag, attribute):
            if let attribute {
                return AttributedString("[\(tag)=\(attribute)]")
            } else {
                return AttributedString("[\(tag)]")
            }
            
        case let .closingTag(tag):
            return AttributedString("[/\(tag)]")
            
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
