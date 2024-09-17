//
//  ArticleElement.swift
//
//
//  Created by Ilia Lubianoi on 11.05.2024.
//

import SwiftUI

public enum ArticleElement: Sendable, Equatable, Hashable {
    case text(TextElement)
    case image(ImageElement)
    case gallery([ImageElement])
    case video(VideoElement)
    case gif(GifElement)
    case button(ButtonElement)
    case bulletList(BulletListElement)
    case table(TableElement)
    case advertisement(AdvertisementElement)
}

// MARK: - Text

public struct TextElement: Sendable, Equatable, Hashable {
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

// MARK: - Image

public struct ImageElement: Sendable, Equatable, Hashable {
    public let url: URL
    public let description: String?
    public let width: Int
    public let height: Int
    
    public var ratioHW: Double {
        return Double(height) / Double(width)
    }
    
    public var ratioWH: Double {
        return Double(width) / Double(height)
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

public struct VideoElement: Sendable, Equatable, Hashable {
    public let id: String
    
    public init(
        id: String
    ) {
        self.id = id
    }
}

// MARK: - GIF

public struct GifElement: Sendable, Equatable, Hashable {
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

public struct ButtonElement: Sendable, Equatable, Hashable {
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

public struct BulletListElement: Sendable, Equatable, Hashable {
    
    public enum BulletType: Sendable, Equatable, Hashable {
        case numeric
        case dotted
    }
    
    public let type: BulletType
    public let elements: [String]
    
    public init(
        type: BulletType,
        elements: [String]
    ) {
        self.type = type
        self.elements = elements
    }
}

// MARK: - BulletListSingle

public struct BulletListSingleElement: Sendable, Equatable, Hashable {
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

// MARK: - TableElement

public struct TableElement: Sendable, Equatable, Hashable {
    public var rows: [TableRowElement]
    
    public init(
        rows: [TableRowElement]
    ) {
        self.rows = rows
    }
}

public struct TableRowElement: Sendable, Equatable, Hashable {
    public var title: String
    public var description: String
    
    public init(
        title: String,
        description: String
    ) {
        self.title = title
        self.description = description
    }
}

// MARK: - Advertismenet Element

public struct AdvertisementElement: Sendable, Equatable, Hashable {
    public let buttonBackgroundColorHex: String
    public let buttonForegroundColorHex: String
    public let buttonText: String
    public let linkUrl: URL
    
    public init(
        buttonBackgroundColorHex: String,
        buttonForegroundColorHex: String,
        buttonText: String,
        linkUrl: URL
    ) {
        self.buttonBackgroundColorHex = buttonBackgroundColorHex
        self.buttonForegroundColorHex = buttonForegroundColorHex
        self.buttonText = buttonText
        self.linkUrl = linkUrl
    }
}

// MARK: - Mock

public extension Array where Element == ArticleElement {
    static let fullMock: [ArticleElement] = [
        .text(.init(text: "Nulla reprehenderit eiusmod consectetur aute voluptate et enim reprehenderit eu minim ea id commodo. Voluptate ipsum amet Lorem culpa pariatur Lorem consectetur dolor veniam officia dolore commodo. Incididunt ea ullamco nulla dolore nostrud pariatur. Sit ex non proident consequat culpa fugiat elit duis aliqua cupidatat labore nostrud officia est.")),
        .image(.init(url: URL(string: "https://4pda.to/s/Zy0hPxnqmrklKWliotRS8kVWdhGv.jpg")!, width: 200, height: 100)),
        .text(.init(text: "Esse id pariatur elit pariatur quis nisi pariatur do aliquip deserunt fugiat aliqua minim Lorem. Anim ut ea ea esse incididunt commodo qui laborum. Commodo aliqua irure culpa quis magna duis aliqua. Voluptate magna ut incididunt. Ipsum ex ex amet eu. Aute dolore deserunt proident elit incididunt occaecat nostrud labore Lorem duis.")),
        .image(.init(url: URL(string: "https://4pda.to/s/Zy0hPxnqmrklKWliotRS8kVWdhGv.jpg")!, description: "Test Description", width: 200, height: 75)),
        .text(.init(text: "Fugiat commodo minim aliquip deserunt laboris Lorem laborum magna voluptate reprehenderit. Elit irure in ut nostrud magna. Tempor consectetur deserunt quis ipsum cillum aute culpa. Consequat velit incididunt nostrud aute amet voluptate voluptate in ex sit dolore sunt voluptate eu commodo. Officia officia cupidatat mollit sunt excepteur id fugiat est sit amet nostrud culpa fugiat id ea.", isQuote: true))
    ]
}

public extension String {
    var asMarkdown: LocalizedStringKey {
        var text = self
        
        // Links
        let regex = #/\[url=\"(?<url>.+?)\"](?<text>.+?)\[/url]/#
        let matches = text.matches(of: regex)
        for match in matches.reversed() {
            let markdownLink = "[\(match.text)](\(match.url))"
            text = text.replacingCharacters(in: match.range, with: markdownLink)
        }
        
        // Italic
        text = text
            .replacingOccurrences(of: "[i]", with: "*")
            .replacingOccurrences(of: "[/i]", with: "*")
            .replacingOccurrences(of: "[b]", with: "**")
            .replacingOccurrences(of: "[/b]", with: "**")
        
        return LocalizedStringKey(text)
    }
}
