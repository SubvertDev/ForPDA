//
//  Bookmark.swift
//  ForPDA
//
//  Created by Xialtal on 30.11.24.
//

import Foundation

public struct Bookmark: Codable, Hashable, Sendable {
    public let id: Int
    public let parentId: Int
    public let name: String
    public let number: Int
    public let format: Format
    public let updatedAt: Date
    public let deleted: Bool
    
    public enum Format: Codable, Sendable, Hashable {
        case folder
        case url(url: URL)
    }
    
    public init(
        id: Int,
        parentId: Int,
        name: String,
        number: Int,
        format: Format,
        updatedAt: Date,
        deleted: Bool
    ) {
        self.id = id
        self.parentId = parentId
        self.name = name
        self.number = number
        self.format = format
        self.updatedAt = updatedAt
        self.deleted = deleted
    }
}

public extension Bookmark {
    static let mockQMS = Bookmark(
        id: 8109925,
        parentId: 0,
        name: "QMS",
        number: 94,
        format: Format.url(url: URL(string: "forum/index.php?act=qms")!),
        updatedAt: .now,
        deleted: false
    )
    
    static let mockForumsList = Bookmark(
        id: 8109981,
        parentId: 0,
        name: "Forums",
        number: 41,
        format: Format.url(url: URL(string: "forum/index.php?act=idx")!),
        updatedAt: .now,
        deleted: false
    )
    
    static let mockForum = Bookmark(
        id: 8109981,
        parentId: 0,
        name: "Some forum",
        number: 1,
        format: Format.url(url: URL(string: "forum/index.php?showforum=5")!),
        updatedAt: .now,
        deleted: false
    )
    
    static let mockTopic = Bookmark(
        id: 8194985,
        parentId: 0,
        name: "Topic example",
        number: 22,
        format: Format.url(
            url: URL(string: "forum/index.php?showtopic=1032094")!
        ),
        updatedAt: .now,
        deleted: false
    )
    
    static let mockTopicPost = Bookmark(
        id: 8109285,
        parentId: 0,
        name: "Some topic post",
        number: 31,
        format: Format.url(
            url: URL(string: "forum/index.php?showtopic=1032094&view=findpost&p=111701205")!
        ),
        updatedAt: .now,
        deleted: false
    )
    
    static let mockUser = Bookmark(
        id: 8109987,
        parentId: 0,
        name: "AirFlare",
        number: 23,
        format: Format.url(
            url: URL(string: "forum/index.php?showuser=6176341")!
        ),
        updatedAt: .now,
        deleted: false
    )
    
    static let mockArticlesList = Bookmark(
        id: 8109653,
        parentId: 0,
        name: "Articles",
        number: 2,
        format: Format.url(url: URL(string: "page/1/")!),
        updatedAt: .now,
        deleted: false
    )
    
    static let mockArticle = Bookmark(
        id: 8119985,
        parentId: 0,
        name: "ForPDA the best!",
        number: 12,
        format: Format.url(url: URL(string: "page/1/")!),
        updatedAt: .now,
        deleted: false
    )
    
    static let mockFolder = Bookmark(
        id: 12,
        parentId: 0,
        name: "Simple folder",
        number: 32,
        format: .folder,
        updatedAt: .now,
        deleted: false
    )
    
    static let mockSubFolder = Bookmark(
        id: 312,
        parentId: 12,
        name: "Subfolder of Simple folder",
        number: 1,
        format: .folder,
        updatedAt: .now,
        deleted: false
    )
}
