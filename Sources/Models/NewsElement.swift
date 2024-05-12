//
//  NewsElement.swift
//
//
//  Created by Ilia Lubianoi on 11.05.2024.
//

import Foundation

public protocol NewsElement {}

public struct TextElement: NewsElement {
    public let text: String
    public let isHeader: Bool
    public let isQuote: Bool
    public let inList: Bool
    public let countedListIndex: Int
    
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

public struct ImageElement: NewsElement {
    public let url: URL
    public let description: String?
    public let width: Int
    public let height: Int
    
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

public struct VideoElement: NewsElement {
    public let url: String
    
    public init(
        url: String
    ) {
        self.url = url
    }
}

public struct GifElement: NewsElement {
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

public struct ButtonElement: NewsElement {
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

public struct BulletListParentElement: NewsElement {
    public let elements: [BulletListElement]
    
    public init(
        elements: [BulletListElement]
    ) {
        self.elements = elements
    }
}

public struct BulletListElement: Hashable {
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
