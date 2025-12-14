//
//  TopicTypeUI.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.12.2024.
//

import SwiftUI
import Models

public indirect enum UITopicType: Hashable, Equatable, Codable, Sendable {
    case text(AttributedString)
    case attachment(Attachment)
    case image(URL)
    case left([UITopicType])
    case center([UITopicType])
    case right([UITopicType])
    case spoiler([UITopicType], AttributedString?)
    case quote([UITopicType], QuoteType?)
    case code(UITopicType, CodeType)
    case hide([UITopicType], Int?)
    case list([UITopicType], ListType)
    case notice([UITopicType], NoticeType)
    case bullet([UITopicType])
    
    // We need custom hasher due to AttributedString bug
    // where TCA doesn't respect custom hasher
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .text(let attributed):
            hasher.combine(0)
            hasher.combine(attributed.stableHash)

        case .attachment(let attachment):
            hasher.combine(1)
            hasher.combine(attachment)

        case .image(let url):
            hasher.combine(2)
            hasher.combine(url)

        case .left(let children):
            hasher.combine(3)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }

        case .center(let children):
            hasher.combine(4)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }

        case .right(let children):
            hasher.combine(5)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }

        case .spoiler(let children, let attributed):
            hasher.combine(6)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }
            hasher.combine(attributed?.stableHash)

        case .quote(let children, let quoteType):
            hasher.combine(7)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }
            hasher.combine(quoteType)

        case .code(let inner, let codeType):
            hasher.combine(8)
            hasher.combine(inner)
            hasher.combine(codeType)

        case .hide(let children, let int):
            hasher.combine(9)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }
            hasher.combine(int)

        case .list(let children, let listType):
            hasher.combine(10)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }
            hasher.combine(listType)

        case .notice(let children, let noticeType):
            hasher.combine(11)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }
            hasher.combine(noticeType)

        case .bullet(let children):
            hasher.combine(12)
            hasher.combine(children.count)
            for child in children { hasher.combine(child) }
        }
    }
}

// MARK: - List Type

public enum ListType: Hashable, Equatable, Codable, Sendable {
    case bullet
    case numeric
    case roman
}

// MARK: - Notice Type

public enum NoticeType: String, Hashable, Equatable, Codable, Sendable {
    case curator = "cur"
    case moderator = "mod"
    case admin = "ex"
    
    public var title: String {
        switch self {
        case .curator:   return "Куратор"
        case .moderator: return "Модератор"
        case .admin:     return "Администратор"
        }
    }
}

// MARK: - Quote Type

public enum QuoteType: Hashable, Equatable, Codable, Sendable {
    case title(String)
    case metadata(QuoteMetadata)
}

// MARK: - Code Type

public enum CodeType: Hashable, Codable, Sendable {
    case none
    case title(String)
}

// MARK: - Quote Metadata

public struct QuoteMetadata: Hashable, Equatable, Codable, Sendable {
    public var name: String
    public var date: String?
    public var postId: Int?
    
    public init(
        name: String,
        date: String?,
        postId: Int? = nil
    ) {
        self.name = name
        self.date = date
        self.postId = postId
    }
    
    public var plain: String {
        if let postId, let date {
            return "name=\"\(name)\" date=\"\(date)\" post=\(postId)"
        } else if let postId {
            return "name=\"\(name)\" post=\(postId)"
        } else if let date {
            return "name=\"\(name)\" date=\"\(date)\""
        } else {
            return "name=\"\(name)\""
        }
    }
}

// MARK: - Extensions

extension AttributedString {
    var stableHash: Int {
        var hasher = Hasher()
        hasher.combine(String(characters))
        hasher.combine(runs.count)
        return hasher.finalize()
    }
}
