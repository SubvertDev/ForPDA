//
//  Comment.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation

public struct Comment: Sendable, Identifiable, Hashable, Codable {
    
    public let id: Int
    public let date: Date
    public let flag: Int
    public let authorId: Int
    public let authorName: String
    public let parentId: Int
    public var childIds: [Int]
    public let text: String
    public var likesAmount: Int
    public let avatarUrl: URL?
    public var nestLevel: Int
    
    public let isDeleted: Bool
    public var isHidden: Bool
    public let isEdited: Bool
    
    public init(
        id: Int,
        date: Date,
        flag: Int,
        authorId: Int,
        authorName: String,
        parentId: Int,
        childIds: [Int],
        text: String,
        likesAmount: Int,
        avatarUrl: URL?,
        nestLevel: Int = 0,
        isDeleted: Bool? = nil,
        isHidden: Bool? = nil,
        isEdited: Bool? = nil
    ) {
        self.id = id
        self.date = date
        self.flag = flag
        self.authorId = authorId
        self.authorName = authorName
        self.parentId = parentId
        self.childIds = childIds
        self.text = text
        self.likesAmount = likesAmount
        self.avatarUrl = avatarUrl
        self.nestLevel = nestLevel
        
        self.isDeleted = isDeleted ?? (flag & 2 != 0)
        self.isHidden = isHidden ?? (flag & 4 != 0)
        self.isEdited = isEdited ?? (flag & 32 != 0)
    }
}

public extension Comment {
    static let mock = Comment(
        id: 0,
        date: Date(timeIntervalSince1970: 1234567890),
        flag: 0,
        authorId: 123,
        authorName: "Test Author",
        parentId: 0,
        childIds: [],
        text: "Some Lorem Impusm Commentary I guess Or Maybe Something Else?",
        likesAmount: 69,
        avatarUrl: URL(string: "https://4pda.to/s/as6yu0QUO7Sw8IXIkLXND7yPqbUz2D9WsZpnOZpIupFFDV6Ct.jpg")!
    )
}

public extension Array where Element == Comment {
    static let mockArray: [Comment] = [
        Comment(
            id: 1,
            date: Date(timeIntervalSince1970: 1722199374),
            flag: 0,
            authorId: 10,
            authorName: "Strubus",
            parentId: 0,
            childIds: [2],
            text: "Айфоны говно!",
            likesAmount: 7,
            avatarUrl: nil
        ),
        Comment(
            id: 2,
            date: Date(timeIntervalSince1970: 1722199474),
            flag: 0,
            authorId: 10,
            authorName: "Strubus",
            parentId: 1,
            childIds: [3],
            text: "Айпады тоже!",
            likesAmount: 0,
            avatarUrl: nil
        ),
        Comment(
            id: 3,
            date: Date(timeIntervalSince1970: 1722199574),
            flag: 0,
            authorId: 10,
            authorName: "Strubus",
            parentId: 2,
            childIds: [],
            text: "Всем пока!",
            likesAmount: 3,
            avatarUrl: nil
        ),
        Comment(
            id: 4,
            date: Date(timeIntervalSince1970: 1722199574),
            flag: 0,
            authorId: 10,
            authorName: "Обыватель",
            parentId: 0,
            childIds: [],
            text: "Опять автор свою статью даже не читал..",
            likesAmount: 5,
            avatarUrl: nil
        )
    ]
}
