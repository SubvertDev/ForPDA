//
//  NewsElement.swift
//
//
//  Created by Ilia Lubianoi on 11.05.2024.
//

import SwiftUI

public enum NewsElement: Equatable, Hashable {
    case text(TextElement)
    case image(ImageElement)
    case video(VideoElement)
    case gif(GifElement)
    case button(ButtonElement)
    case bulletList(BulletListElement)
}

// MARK: - Text

public struct TextElement: Equatable, Hashable {
    public let text: String
    public let isHeader: Bool
    public let isQuote: Bool
    public let inList: Bool
    public let countedListIndex: Int
    
    public var markdown: LocalizedStringKey {
        let regex = #/<a href="(.+?) target="_blank">(.*?)</a>/#
//        let regex = try! Regex("<a href=\"(.+?)\">(.*?)</a>")
        
        if let match = text.firstMatch(of: regex) {
            var url = match.1
            let linkText = match.2
            if !url.contains("https") { // RELEASE: No-https links are 4pda ones, need to implement deeplink on tap
                url = "https:" + url
            }
            
            let markdownLink = "[\(linkText)](\(url))"
            
            return LocalizedStringKey(text.replacingCharacters(in: match.range, with: markdownLink))
        } else {
            return LocalizedStringKey(text)
        }
    }
    
    public init(
        text: String,
         isHeader: Bool = false,
         isQuote: Bool = false,
         inList: Bool = false,
         countedListIndex: Int = 0
    ) {
        self.text = text
        self.isHeader = isHeader
        self.isQuote = isQuote
        self.inList = inList
        self.countedListIndex = countedListIndex
    }
}

// MARK: - Image

public struct ImageElement: Equatable, Hashable {
    public let url: URL
    public let description: String?
    public let width: Int
    public let height: Int
    
    public var ratioHW: Double {
        return Double(height) / Double(width)
    }
    
    public init(
        url: URL,
        description: String? = nil,
        width: Int,
        height: Int
    ) {
        self.url = url
        self.description = description
        self.width = width
        self.height = height
    }
}

// MARK: - Video

public struct VideoElement: Equatable, Hashable {
    public let url: String
    
    public init(
        url: String
    ) {
        self.url = url
    }
}

// MARK: - GIF

public struct GifElement: Equatable, Hashable {
    public let url: URL
    public let width: Int
    public let height: Int
    
    public init(
        url: URL,
        width: Int,
        height: Int
    ) {
        self.url = url
        self.width = width
        self.height = height
    }
}

// MARK: - Button

public struct ButtonElement: Equatable, Hashable {
    public let text: String
    public let url: URL
    
    public init(
        text: String,
        url: URL
    ) {
        self.text = text
        self.url = url
    }
}

// MARK: - BulletList

public struct BulletListElement: Equatable, Hashable {
    public let elements: [BulletListSingleElement]
    
    public init(
        elements: [BulletListSingleElement]
    ) {
        self.elements = elements
    }
}

// MARK: - BulletListSingle

public struct BulletListSingleElement: Equatable, Hashable {
    public var title: String
    public var description: [String]
    
    public init(
        title: String,
        description: [String]
    ) {
        self.title = title
        self.description = description
    }
}

// MARK: - Mock

public extension Array where Element == NewsElement {
    static let fullMock: [NewsElement] = [
        .text(.init(text: "Nulla reprehenderit eiusmod consectetur aute voluptate et enim reprehenderit eu minim ea id commodo. Voluptate ipsum amet Lorem culpa pariatur Lorem consectetur dolor veniam officia dolore commodo. Incididunt ea ullamco nulla dolore nostrud pariatur. Sit ex non proident consequat culpa fugiat elit duis aliqua cupidatat labore nostrud officia est.")),
        .image(.init(url: URL(string: "https://4pda.to/s/Zy0hPxnqmrklKWliotRS8kVWdhGv.jpg")!, width: 200, height: 100)),
        .text(.init(text: "Esse id pariatur elit pariatur quis nisi pariatur do aliquip deserunt fugiat aliqua minim Lorem. Anim ut ea ea esse incididunt commodo qui laborum. Commodo aliqua irure culpa quis magna duis aliqua. Voluptate magna ut incididunt. Ipsum ex ex amet eu. Aute dolore deserunt proident elit incididunt occaecat nostrud labore Lorem duis.")),
        .image(.init(url: URL(string: "https://4pda.to/s/Zy0hPxnqmrklKWliotRS8kVWdhGv.jpg")!, description: "Test Description", width: 200, height: 75)),
        .text(.init(text: "Fugiat commodo minim aliquip deserunt laboris Lorem laborum magna voluptate reprehenderit. Elit irure in ut nostrud magna. Tempor consectetur deserunt quis ipsum cillum aute culpa. Consequat velit incididunt nostrud aute amet voluptate voluptate in ex sit dolore sunt voluptate eu commodo. Officia officia cupidatat mollit sunt excepteur id fugiat est sit amet nostrud culpa fugiat id ea.", isQuote: true))
    ]
}
