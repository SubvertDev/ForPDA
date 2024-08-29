//
//  Event.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import Foundation

public protocol Event {
    var name: String { get }
    var properties: [String: String]? { get }
}

// RELEASE: Test if this works accurately
public func eventName(for object: Any) -> String {
    if let string = Mirror(reflecting: object).children.first?.label {
        return string.inProperCase
    } else {
        return String(describing: object).inProperCase
    }
}

public extension String { // RELEASE: Move public or make private
    var inProperCase: String {
        // Regular expressions to match different case styles
        let camelCasePattern = "([a-z0-9])([A-Z])"
        let snakeKebabPattern = "[-_]"

        // Convert camelCase to space-separated words
        let camelCaseRegex = try! NSRegularExpression(pattern: camelCasePattern, options: [])
        let camelCaseTransformed = camelCaseRegex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count), withTemplate: "$1 $2")

        // Replace snake_case or kebab-case with spaces
        let snakeKebabRegex = try! NSRegularExpression(pattern: snakeKebabPattern, options: [])
        let separatedWords = snakeKebabRegex.stringByReplacingMatches(in: camelCaseTransformed, options: [], range: NSRange(location: 0, length: camelCaseTransformed.utf16.count), withTemplate: " ")

        // Split into words, capitalize each word, and join them with spaces
        let words = separatedWords.components(separatedBy: .whitespaces)
        let capitalizedWords = words.map { $0.capitalized }
        let properCaseString = capitalizedWords.joined(separator: " ")

        return properCaseString
    }
}
