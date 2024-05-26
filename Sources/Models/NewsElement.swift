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
