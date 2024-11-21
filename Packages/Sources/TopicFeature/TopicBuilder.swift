//
//  TopicBuilder.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 18.11.2024.
//

import SwiftUI
import SharedUI
import ComposableArchitecture

public struct QuoteInfo: Hashable {
    public let name: String
    public let date: Date
    public let postId: Int
}

public enum TopicType: Hashable {
    case text(NSAttributedString)
    case image(Int)
    case center([TopicType])
    case right([TopicType])
    case spoiler([TopicType], NSAttributedString?)
    case quote(NSAttributedString, QuoteInfo)
}

public struct TopicBuilder {
    
    public static func build(from content: NSAttributedString) throws -> [TopicType] {
        var result: [TopicType] = []
        var remainingText = content
        
        while remainingText.length > 0 {
            let tags = [
                "[spoiler=",
                "[spoiler]",
                "[center]",
                "[right]",
                "[attachment=",
                "[quote "
            ] // Add new tags as needed
            
            let ranges: [NSRange] = tags.compactMap { tag in
                if let range = remainingText.string.range(of: tag) {
                    let location = remainingText.string.distance(from: remainingText.string.startIndex, to: range.lowerBound)
                    return NSRange(location: location, length: tag.count)
                }
                return nil
            }

            // Find the earliest tag
            let nextTagRange = ranges.min { $0.location < $1.location }

            if let nextTagRange {
                let prefixRange = NSRange(location: 0, length: nextTagRange.location)
                if prefixRange.length > 0 {
                    let prefixText = remainingText.attributedSubstring(from: prefixRange)
                    
                    // Check if the plain text (string) of the prefix is non-empty after trimming
                    if !prefixText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let trimmedText = remainingText.trimmedAttributedString()
                        let text = extractSnapback(in: trimmedText)
                        result.append(.text(text))
                    }
                }
                
                // Extract the tag (with attributes preserved)
                let nextTag = remainingText.attributedSubstring(from: nextTagRange).string
                
                switch nextTag {
                case "[spoiler=", "[spoiler]":
                    let spoiler = extractSpoiler(from: remainingText, baseStartTag: "[spoiler]", endTag: "[/spoiler]")
                    let types = try! TopicBuilder.build(from: spoiler.text)
                    result.append(.spoiler(types, spoiler.additionalInfo))
                    remainingText = spoiler.remainingText ?? NSAttributedString(string: "")
                    
                case "[center]":
                    let parts = extractText(from: remainingText, startTag: "[center]", endTag: "[/center]")
                    let types = try! TopicBuilder.build(from: parts.0)
                    result.append(.center(types))
                    remainingText = parts.1 ?? NSAttributedString(string: "")
                    
                case "[right]":
                    let parts = extractText(from: remainingText, startTag: "[right]", endTag: "[/right]")
                    let types = try! TopicBuilder.build(from: parts.0)
                    result.append(.right(types))
                    remainingText = parts.1 ?? NSAttributedString(string: "")
                    
                case "[attachment=":
                    let parts = extractText(from: remainingText, startTag: "[attachment=\"", endTag: "\"]")
                    let imageId = parts.0.string.split(separator: ":")[0]
                    result.append(.image(Int(imageId)!))
                    remainingText = parts.1 ?? NSAttributedString(string: "")
                    
                case "[quote ":
                    let parts = extractText(from: remainingText, startTag: "[quote ", endTag: "[/quote]")
                    let quoteParts = parts.0.components(separatedBy: "]")
                    let quoteInfo = parseQuoteInfo(quoteParts[0])
                    result.append(.quote(dropAndJoinAttributedStrings(quoteParts), quoteInfo))
                    remainingText = parts.1 ?? NSAttributedString(string: "")
                    
                default:
                    break
                }
            } else {
                if remainingText.length > 0 {
                    let trimmedText = remainingText.trimmedAttributedString()
                    let text = extractSnapback(in: trimmedText)
                    result.append(.text(text))
                }
                break
            }
        }

        return result
    }
    
    // MARK: - Extract Quote Info
    
    private static func parseQuoteInfo(_ attributedString: NSAttributedString) -> QuoteInfo {
        let plainText = attributedString.string
        
        let pattern = #"name="([^"]+)" date="([^"]+)" post=(\d+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            fatalError("Invalid regex pattern")
        }
        
        let range = NSRange(location: 0, length: plainText.utf16.count)
        if let match = regex.firstMatch(in: plainText, options: [], range: range) {
            let name = match.range(at: 1).location != NSNotFound ? (plainText as NSString).substring(with: match.range(at: 1)) : nil
            let date = match.range(at: 2).location != NSNotFound ? (plainText as NSString).substring(with: match.range(at: 2)) : nil
            let post = match.range(at: 3).location != NSNotFound ? (plainText as NSString).substring(with: match.range(at: 3)) : nil
            
            return QuoteInfo(name: name!, date: convertToDate(from: date!)!, postId: Int(post!)!)
        } else {
            fatalError()
        }
    }
    
    private static  func convertToDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy, HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
    
    private static func dropAndJoinAttributedStrings(_ attributedStrings: [NSAttributedString]) -> NSAttributedString {
        let remainingStrings = attributedStrings.dropFirst()
        let result = NSMutableAttributedString()
        for string in remainingStrings {
            result.append(string)
        }
        return result
    }
    
    // MARK: - Extract Snapback
    
    private static func extractSnapback(in attributedString: NSAttributedString) -> (NSAttributedString) {
        let plainText = attributedString.string
        let pattern = #"\[snapback\](\d+)\[/snapback\]"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            fatalError()
        }
        
        let matches = regex.matches(in: plainText, options: [], range: NSRange(location: 0, length: plainText.utf16.count))
        
        // Prepare to collect extracted data
        var extractedNumbers = [Int]()
        var positions = [Int]()
        
        // Create a mutable copy of the attributed string
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        // Prepare image attachment
        let image = Image.snapback
        let attachment = NSTextAttachment(image: image)
        attachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)
        let snapbackAttributedString = NSAttributedString(attachment: attachment)
        
        // Adjust offset to account for text removal
        var offset = 0
        
        for match in matches {
            // Extract the number
            let numberRange = match.range(at: 1)
            let number = Int((plainText as NSString).substring(with: numberRange))!
            extractedNumbers.append(number)
            
            // Record the adjusted position
            let startPosition = match.range.location - offset
            positions.append(startPosition)
            
            // Remove the `[snapback]...[/snapback]` tags
            let fullRange = NSRange(location: match.range.location - offset, length: match.range.length)
            mutableAttributedString.replaceCharacters(in: fullRange, with: "")
            
            // Insert the snapback image at the recorded position
            mutableAttributedString.insert(snapbackAttributedString, at: startPosition)
            
            // Update the offset to account for the removed range
            offset += match.range.length
        }
        
        return mutableAttributedString
    }
    
    // MARK: - Extract Spoiler
    
    private struct Spoiler {
        let text: NSAttributedString
        let additionalInfo: NSAttributedString?
        let remainingText: NSAttributedString?
    }
    
    private static func extractSpoiler(from text: NSAttributedString, baseStartTag: String, endTag: String) -> Spoiler {
        let fullText = text.string
        var stack: [(String.Index, NSAttributedString?)] = [] // Stack to track nested start tags and their additional info
        var currentIndex = fullText.startIndex

        while let nextTag = findNextTag(in: fullText, startTagRegex: try! NSRegularExpression(pattern: "\\[spoiler(=[^\\]]+)?\\]", options: []), endTag: endTag, from: currentIndex) {
            if nextTag.isStartTag {
                // Extract full tag as attributed string
                let fullTag = text.attributedSubstring(from: NSRange(nextTag.range, in: fullText))
                
                // Extract additional info (if available)
                let additionalInfo = extractAdditionalInfo(from: fullTag, baseStartTag: baseStartTag)

                // Push the start tag and its additional info onto the stack
                stack.append((nextTag.range.lowerBound, additionalInfo))
                currentIndex = nextTag.range.upperBound
            } else if let (start, additionalInfo) = stack.popLast() {
                // Found an end tag with a matching start tag on the stack
                let startTagEndIndex = fullText.distance(from: fullText.startIndex, to: fullText.index(start, offsetBy: baseStartTag.count))
                let endTagStartIndex = fullText.distance(from: fullText.startIndex, to: nextTag.range.lowerBound)
                let endTagEndIndex = fullText.distance(from: fullText.startIndex, to: nextTag.range.upperBound)

                // If the stack is empty, this is the outermost matched pair
                if stack.isEmpty {
                    var location = startTagEndIndex
                    var length = endTagStartIndex - startTagEndIndex
                    if let additionalInfo {
                        location += additionalInfo.length + 1
                        length -= additionalInfo.length + 1
                    }
                    let matchedRange = NSRange(location: location, length: length)
                    let remainingRange = NSRange(location: endTagEndIndex, length: text.length - endTagEndIndex)

                    let extractedText = text.attributedSubstring(from: matchedRange)
                    let remainingText = remainingRange.length > 0 ? text.attributedSubstring(from: remainingRange) : nil

//                    return (extractedText, additionalInfo, remainingText)
                    return Spoiler(
                        text: extractedText,
                        additionalInfo: additionalInfo,
                        remainingText: remainingText
                    )
                }
                currentIndex = nextTag.range.upperBound
            } else {
                // Not a valid tag, move to the next character
                currentIndex = fullText.index(after: nextTag.range.lowerBound)
            }
        }

        // If no match is found, return empty results
        return Spoiler(
            text: NSAttributedString(string: ""),
            additionalInfo: nil,
            remainingText: nil
        )
    }

    private static func findNextTag(in text: String, startTagRegex: NSRegularExpression, endTag: String, from currentIndex: String.Index) -> (range: Range<String.Index>, isStartTag: Bool)? {
        let searchRange = NSRange(currentIndex..<text.endIndex, in: text)

        // Find the next start tag
        let startMatch = startTagRegex.firstMatch(in: text, options: [], range: searchRange)
        let startTagRange = startMatch.flatMap { Range($0.range, in: text) }

        // Find the next end tag
        let endTagRange = text.range(of: endTag, range: currentIndex..<text.endIndex)

        // Compare positions of the start and end tags
        if let start = startTagRange, let end = endTagRange {
            return start.lowerBound < end.lowerBound ? (range: start, isStartTag: true) : (range: end, isStartTag: false)
        } else if let start = startTagRange {
            return (range: start, isStartTag: true)
        } else if let end = endTagRange {
            return (range: end, isStartTag: false)
        }

        return nil
    }

    private static func extractAdditionalInfo(from tag: NSAttributedString, baseStartTag: String) -> NSAttributedString? {
        let fullTag = tag.string
        guard let equalSignRange = fullTag.range(of: "=") else { return nil }
        
        let start = tag.string.index(after: equalSignRange.lowerBound)
        let end = tag.string.index(before: fullTag.endIndex)
        
        let attributedRange = NSRange(location: fullTag.distance(from: fullTag.startIndex, to: start),
                                      length: fullTag.distance(from: start, to: end))
        return tag.attributedSubstring(from: attributedRange)
    }
    
    // MARK: - Extract Text
    
    private static func extractText(from text: NSAttributedString, startTag: String, endTag: String) -> (NSAttributedString, NSAttributedString?) {
        let fullText = text.string
        guard let startRange = fullText.range(of: startTag),
              let endRange = fullText.range(of: endTag, range: startRange.upperBound..<fullText.endIndex) else {
            return (NSAttributedString(string: ""), nil)
        }

        // Calculate the NSRange equivalents for the attributed string
        let startTagEndIndex = fullText.distance(from: fullText.startIndex, to: startRange.upperBound)
        let endTagStartIndex = fullText.distance(from: fullText.startIndex, to: endRange.lowerBound)
        let endTagEndIndex = fullText.distance(from: fullText.startIndex, to: endRange.upperBound)

        // Extract attributed substrings
        let extractedRange = NSRange(location: startTagEndIndex, length: endTagStartIndex - startTagEndIndex)
        let remainingRange = NSRange(location: endTagEndIndex, length: text.length - endTagEndIndex)

        let extractedText = text.attributedSubstring(from: extractedRange)
        let remainingText = remainingRange.length > 0 ? text.attributedSubstring(from: remainingRange) : nil

        return (extractedText, remainingText)
    }
}

extension NSAttributedString {

    /// Trims new lines and whitespaces off the beginning and the end of attributed strings
    func trimmedAttributedString() -> NSAttributedString {
        let invertedSet = CharacterSet.whitespacesAndNewlines.inverted
        let startRange = string.rangeOfCharacter(from: invertedSet)
        let endRange = string.rangeOfCharacter(from: invertedSet, options: .backwards)
        guard let startLocation = startRange?.lowerBound, let endLocation = endRange?.lowerBound else {
            return NSAttributedString(string: string)
        }

        let trimmedRange = startLocation...endLocation
        return attributedSubstring(from: NSRange(trimmedRange, in: string))
    }
}


private extension NSAttributedString {
    func components(separatedBy separator: String) -> [NSAttributedString] {
        var result = [NSAttributedString]()
        let separatedStrings = string.components(separatedBy: separator)
        var range = NSRange(location: 0, length: 0)
        for string in separatedStrings {
            range.length = string.utf16.count
            let attributedString = attributedSubstring(from: range)
            result.append(attributedString)
            range.location += range.length + separator.utf16.count
        }
        return result
    }
}
