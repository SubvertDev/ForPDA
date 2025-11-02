//
//  BBCodeParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.09.2024.
//

import UIKit
import SwiftUI
import SharedUI
import ZMarkupParser

public final class BBCodeParser {
    
    // MARK: - Fast Parsing
    
    nonisolated(unsafe) public static var fastParser = ZHTMLParserBuilder.initWithDefault().build()
    
    public static func fastParse(_ text: String) -> String {
        return fastParser.render(text).string
    }
    
    // MARK: - Helpers
    
    private static func transformCodeTags(in string: String) -> String {
        let pattern = "\\[code\\](.*?)\\[/code\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)

        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        var transformedString = string

        regex.enumerateMatches(in: string, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let matchRange = Range(match.range(at: 1), in: string) else { return }

            let codeContent = string[matchRange]
            let transformedCodeContent = codeContent
                .replacingOccurrences(of: "&lt;", with: "≤")
                .replacingOccurrences(of: "%gt;", with: "≥")
            
            transformedString = transformedString.replacingOccurrences(of: String(codeContent), with: transformedCodeContent)
        }

        return transformedString
    }
    
    private static func reverseTransformCodeTags(in attributedString: NSAttributedString) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableAttributedString.length)
        
        // Define regex to find [code]...[/code]
        let pattern = "\\[code\\](.*?)\\[/code\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        
        // Enumerate matches to find ranges of `[code]` blocks
        regex.enumerateMatches(in: mutableAttributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match else { return }
            let codeRange = match.range(at: 1) // Captured content inside [code]...[/code]

            // Extract the text within the range
            let codeContent = mutableAttributedString.attributedSubstring(from: codeRange).string

            // Replace ≤ with < and ≥ with >
            let transformedText = codeContent
                .replacingOccurrences(of: "≤", with: "<")
                .replacingOccurrences(of: "≥", with: ">")

            // Replace the range in the attributed string
            let transformedAttributedString = NSAttributedString(string: transformedText, attributes: mutableAttributedString.attributes(at: codeRange.location, effectiveRange: nil))
            mutableAttributedString.replaceCharacters(in: codeRange, with: transformedAttributedString)
        }
        
        return mutableAttributedString
    }
}

extension NSAttributedString {
    func replacingOccurrences(of target: String, with replacement: String) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: self.length)
        let regex = try! NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: target))
        
        let matches = regex.matches(in: self.string, options: [], range: range)
        for match in matches.reversed() { // Reverse to avoid messing up ranges
            let matchRange = match.range
            mutableAttributedString.replaceCharacters(in: matchRange, with: replacement)
        }
        
        return mutableAttributedString
    }
}

// MARK: - Forum Colors

public enum ForumColors: CaseIterable {
    // Breaks color on light/dark mode change
//    case black
//    case white
    case skyblue
    case royalblue
    case blue
    case darkblue
    case orange
    case orangered
    case crimson
    case red
    case darkred
    case green
    case limegreen
    case seagreen
    case deeppink
    case tomato
    case coral
    case purple
    case indigo
    case burlywood
    case sandybrown
    case sienna
    case chocolate
    case teal
    case silver
    
    public var hexColor: (String, String) {
        switch self {
            // Breaks color on light/dark mode change
//        case .black:        return ("000000", "909090")
//        case .white:        return ("FFFFFF", "FFFFFF")
        case .skyblue:      return ("87CEEB", "87CEEB")
        case .royalblue:    return ("4169E1", "4169E1")
        case .blue:         return ("0000FF", "0000FF")
        case .darkblue:     return ("00008B", "00008B")
        case .orange:       return ("FFA500", "FFA500")
        case .orangered:    return ("FF4500", "FF4500")
        case .crimson:      return ("DC143C", "DC143C")
        case .red:          return ("FF0000", "FF0000")
        case .darkred:      return ("8B0000", "CB4040")
        case .green:        return ("008001", "20A020")
        case .limegreen:    return ("33CD32", "32CD32")
        case .seagreen:     return ("2E8B58", "2E8B57")
        case .deeppink:     return ("FF1393", "FF1493")
        case .tomato:       return ("FF6348", "FF6347")
        case .coral:        return ("FF7F50", "FF7F50")
        case .purple:       return ("800080", "A020A0")
        case .indigo:       return ("4B0082", "6B20A2")
        case .burlywood:    return ("DEB887", "DEB887")
        case .sandybrown:   return ("F4A361", "F4A460")
        case .sienna:       return ("A0522D", "A0522D")
        case .chocolate:    return ("D3691E", "D2691E")
        case .teal:         return ("008080", "008080")
        case .silver:       return ("C0C0C0", "C0C0C0")
        }
    }
}

extension UIColor {
    convenience init(dynamicTuple: (String, String)) {
        self.init(dynamicProvider: { traits in
            let hex = traits.userInterfaceStyle == .dark ? dynamicTuple.1 : dynamicTuple.0
            return UIColor(hex: hex) ?? .label
        })
    }
}

extension UIColor {
    convenience init?(hex: String) {
        guard hex.count == 6, let hexNumber = UInt32(hex, radix: 16) else {
            return nil
        }
        
        let r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hexNumber & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIColor {
    func toHexString() -> String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            // The color must be in the RGB color space to extract components
            return nil
        }
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
