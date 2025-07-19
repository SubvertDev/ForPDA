//
//  TopicTypeUI.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.12.2024.
//

import SwiftUI

public indirect enum TopicTypeUI: Hashable, Equatable, Codable, Sendable {
    case text(AttributedString)
    case attachment(Post.Attachment)
    case image(URL)
    case left([TopicTypeUI])
    case center([TopicTypeUI])
    case right([TopicTypeUI])
    case spoiler([TopicTypeUI], AttributedString?)
    case quote([TopicTypeUI], QuoteType?)
    case code(TopicTypeUI, CodeType)
    case hide([TopicTypeUI], Int?)
    case list([TopicTypeUI], ListType)
    case notice([TopicTypeUI], NoticeType)
    case bullet([TopicTypeUI])
}

public enum ListType: Hashable, Equatable, Codable, Sendable {
    case bullet
    case numeric
    case roman
}

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

public enum QuoteType: Hashable, Equatable, Codable, Sendable {
    case title(String)
    case metadata(QuoteMetadata)
}

public enum CodeType: Hashable, Codable, Sendable {
    case none
    case title(String)
}

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
