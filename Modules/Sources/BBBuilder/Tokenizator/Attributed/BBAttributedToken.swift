//
//  BBAttributedToken.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.03.2025.
//

import Foundation

public enum BBAttributedToken: Equatable {
    case openingTag(BBTag, NSAttributedString?)
    case closingTag(BBTag)
    case text(NSAttributedString)
}

public extension BBAttributedToken {
    var description: NSAttributedString {
        switch self {
        case let .openingTag(tag, attribute):
            if let attribute {
                return NSAttributedString(string: "[\(tag)=\(attribute.string)]", attributes: BBRenderer.defaultAttributes)
            } else {
                return NSAttributedString(string: "[\(tag)]", attributes: BBRenderer.defaultAttributes)
            }
            
        case let .closingTag(tag):
            return NSAttributedString(string: "[/\(tag)]", attributes: BBRenderer.defaultAttributes)
            
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
