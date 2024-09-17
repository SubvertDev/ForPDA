//
//  ArticleElementParser.swift
//
//
//  Created by Ilia Lubianoi on 05.07.2024.
//

import Foundation
import Models

public struct ArticleElementParser {
    
    public static func parse(from article: Article) throws -> [ArticleElement] {
        var result: [ArticleElement] = []
        var remainingText = article.description

        while !remainingText.isEmpty {
            // TODO: Extract size value in [size]
            let tags = [
                "[quote]",
                "[center][blockbg=",
                "[center]",
                "[size=4]",
                "[size=3]",
                "[attachment=",
                "[table]",
                "[list=1]",
                "[list]",
            ] // Add new tags as needed
            
            let ranges = tags.compactMap { remainingText.range(of: $0) }

            let nextTagRange = ranges.min(by: { $0.lowerBound < $1.lowerBound })
            
            if let nextTagRange {
                let nextTag = String(remainingText[nextTagRange.lowerBound..<remainingText.index(before: nextTagRange.upperBound)]) + "]"
                let prefixText = String(remainingText[..<nextTagRange.lowerBound])
                if !prefixText.isEmpty {
                    if !prefixText.trim().isEmpty {
                        result.append(.text(.init(text: prefixText.trim())))
                    }
                }
                
                if nextTag == "[quote]" {
                    // Extracting quote from text
                    let parts = extractText(from: remainingText, startTag: "[quote]", endTag: "[/quote]")
                    result.append(.text(.init(text: parts.0.trim(), isQuote: true)))
                    remainingText = parts.1 ?? ""
                } else if nextTag == "[center][blockbg]" {
                    let parts = extractText(from: remainingText, startTag: "[center][blockbg=", endTag: "[/blockbg][/center]")
                    let advertisementElement = try extractAdvertisementElement(text: parts.0)
                    result.append(.advertisement(advertisementElement))
                    remainingText = ""
                    // remainingText = parts.1 ?? "" // TODO: Everything after advertisement is cut off
                } else if nextTag == "[center]" {
                    let parts = extractText(from: remainingText, startTag: "[center]", endTag: "[/center]")
                    // There's three known types of center tag atm:
                    // Attachment with spoiler (images carousel aka gallery)
                    // Attachment (single image)
                    // Youtube (video)
                    if parts.0.contains("attachment") && parts.0.contains("spoiler") {
                        let imageElements = try extractImageElements(text: parts.0, attachments: article.attachments)
                        result.append(.gallery(imageElements))
                    } else if parts.0.contains("attachment") {
                        let imageElement = try extractImageElement(text: parts.0, attachments: article.attachments)
                        result.append(.image(imageElement))
                    } else if parts.0.contains("youtube") {
                        let videoElement = try extractVideoElement(text: parts.0)
                        result.append(.video(videoElement))
                    }
                    remainingText = parts.1 ?? ""
                } else if nextTag == "[size=4]" || nextTag == "[size=3]" {
                    let parts = extractText(from: remainingText, startTag: nextTag, endTag: "[/size]")
                    if !parts.0.trim().isEmpty { // Quick fix for empty texts under headers
                        result.append(.text(.init(text: parts.0, isHeader: true)))
                    }
                    remainingText = parts.1 ?? ""
                } else if nextTag == "[attachment]" { // Centerless attachment
                    let parts = extractText(from: remainingText, startTag: "[attachment=\"", endTag: ":dummy\"]")
                    let imageElement = try extractImageElement(text: parts.0, attachments: article.attachments)
                    result.append(.image(imageElement))
                    remainingText = parts.1 ?? ""
                } else if nextTag == "[table]" {
                    let parts = extractText(from: remainingText, startTag: "[table]", endTag: "[/table]")
                    let tableElement = try extractTableElement(text: parts.0)
                    result.append(.table(tableElement))
                    remainingText = parts.1 ?? ""
                } else if nextTag == "[list=1]" {
                    let parts = extractText(from: remainingText, startTag: "[list=1]", endTag: "[/list]")
                    let bulletListElement = try extractBulletListElement(type: .numeric, text: parts.0)
                    result.append(.bulletList(bulletListElement))
                    remainingText = parts.1 ?? ""
                } else if nextTag == "[list]" {
                    let parts = extractText(from: remainingText, startTag: "[list]", endTag: "[/list]")
                    let bulletListElement = try extractBulletListElement(type: .dotted, text: parts.0)
                    result.append(.bulletList(bulletListElement))
                    remainingText = parts.1 ?? ""
                }
            } else {
                if !remainingText.trim().isEmpty {
                    result.append(.text(.init(text: remainingText.trim())))
                }
                break
            }
        }

        return result
    }
    
    // MARK: - Helpers
    
    private static func extractText(from text: String, startTag: String, endTag: String) -> (String, String?) {
        if let startRange = text.range(of: startTag), let endRange = text.range(of: endTag, range: startRange.upperBound..<text.endIndex) {
            let extractedText = String(text[startRange.upperBound..<endRange.lowerBound])
            let remainingText = String(text[endRange.upperBound..<text.endIndex])
            return (extractedText, remainingText)
        }
        return ("", nil)
    }
    
    // MARK: - Image
    
    /// [attachment=\"1:dummy\"] -> 1
    private static func extractImageElement(text: String, attachments: [Attachment]) throws -> ImageElement {
        let pattern = #/=\"(\d+):/#
        
        var id: Int
        if let match = text.firstMatch(of: pattern), let number = Int(match.output.1) {
            id = number
        } else if let number = Int(text) { // Centerless attachment
            id = number
        } else {
            throw ParsingError.failedToExtractImage
        }
        
        let attachment = attachments[id - 1]
        var url = attachment.smallUrl
        if let fullUrl = attachment.fullUrl { url = fullUrl }
        return ImageElement(url: url, width: attachment.width, height: attachment.height)
    }
    
    // MARK: - Images
    
    /// [attachment=\"1:dummy\"] -> 1
    private static func extractImageElements(text: String, attachments: [Attachment]) throws -> [ImageElement] {
        let pattern = #/=\"(\d+):/#
        
        var imageElements: [ImageElement] = []
        
        for match in text.matches(of: pattern) {
            let attachment = attachments[Int(match.output.1)! - 1]
            var url: URL = attachment.smallUrl
            if let fullUrl = attachment.fullUrl { url = fullUrl }
            let element = ImageElement(url: url, width: attachment.width, height: attachment.height)
            imageElements.append(element)
        }
        
        if imageElements.isEmpty {
            throw ParsingError.failedToExtractImages
        } else {
            return imageElements
        }
    }
    
    // MARK: - Video
    
    /// [youtube=Bfo2xIeaOAE:640:360:::0] -> Bfo2xIeaOAE
    private static func extractVideoElement(text: String) throws -> VideoElement {
        let pattern = #/=(.+?):/#
        
        if let match = text.firstMatch(of: pattern) {
            return VideoElement(id: String(match.output.1))
        } else {
            throw ParsingError.failedToExtractVideo
        }
    }
    
    // MARK: - Table
    
    private static func extractTableElement(text: String) throws -> TableElement {
        let lines = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "[/tr] [tr]")
        
        var components: [String] = []
        for component in lines {
            let line = component
                .components(separatedBy: "[/td] [td]")
            components.append(contentsOf: line)
        }

        var titles: [String] = []
        var descriptions: [String] = []
        for index in components.indices {
            if index % 2 == 0 {
                titles.append(
                    String(
                        components[index]
                            .dropFirst(index == 0 ? 18 : 14)
                            .dropLast(12)
                    )
                )
            } else {
                descriptions.append(
                    String(
                        components[index]
                            .dropLast(index == components.count - 1 ? 10 : 5)
                    )
                )
            }
        }

        let rows = Array(zip(titles, descriptions))
            .map { TableRowElement(title: $0.0, description: $0.1) }
        
        return TableElement(rows: rows)
    }
    
    // MARK: - Bullet List
    
    private static func extractBulletListElement(type: BulletListElement.BulletType, text: String) throws -> BulletListElement {
        let components = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "[*]")
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        return BulletListElement(type: type, elements: components)
    }
    
    // MARK: - Advertisement Element
    
    private static func extractAdvertisementElement(text: String) throws -> [AdvertisementElement] {
        let components = text.components(separatedBy: "/blockbg] [blockbg")
        var elements: [AdvertisementElement] = []
        
        for component in components {
            var pattern = /\[background=\#(\w+)\]/
            let buttonBackgroundColorHex: String
            if let match = component.firstMatch(of: pattern) {
                buttonBackgroundColorHex = String(match.output.1)
            } else {
                throw ParsingError.failedToExtractAdvertisment
            }
            
            pattern = /\[color=\#(\w+)\]/
            let buttonForegroundColorHex: String
            if let match = component.firstMatch(of: pattern) {
                buttonForegroundColorHex = String(match.output.1)
            } else {
                throw ParsingError.failedToExtractAdvertisment
            }
            
            let buttonPattern = /color=#(\w+)\](.+)\[\/color/
            let buttonText: String
            if let match = component.firstMatch(of: buttonPattern) {
                buttonText = String(match.output.2)
            } else {
                throw ParsingError.failedToExtractAdvertisment
            }
            
            pattern = /\[url=(.+)\]\[color/
            let linkUrl: URL
            if let match = component.firstMatch(of: pattern) {
                if let url = URL(string: String(match.output.1)) {
                    linkUrl = url
                } else {
                    throw ParsingError.failedToExtractAdvertisment
                }
            } else {
                throw ParsingError.failedToExtractAdvertisment
            }
            
            let element = AdvertisementElement(
                buttonBackgroundColorHex: buttonBackgroundColorHex,
                buttonForegroundColorHex: buttonForegroundColorHex,
                buttonText: buttonText,
                linkUrl: linkUrl
            )
            elements.append(element)
        }
        
        return elements
    }
}

private extension String {
    func trim() -> String {
        return self
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\n ", with: "\n")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
