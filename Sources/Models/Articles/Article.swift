//
//  Article.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation

public struct Article: Hashable {

    public let id: Int
    public let date: Date
    public let authorId: Int
    public let authorName: String
    public let commentsAmount: Int
    public let imageUrl: URL
    public let title: String
    public let description: String
    public let attachments: [Attachment]
    public let tags: [Tag]
    public let comments: [Comment]
    
    public init(
        id: Int,
        date: Date,
        authorId: Int,
        authorName: String,
        commentsAmount: Int,
        imageUrl: URL,
        title: String,
        description: String,
        attachments: [Attachment],
        tags: [Tag],
        comments: [Comment]
    ) {
        self.id = id
        self.date = date
        self.authorId = authorId
        self.authorName = authorName
        self.commentsAmount = commentsAmount
        self.imageUrl = imageUrl
        self.title = title
        self.description = description
        self.attachments = attachments
        self.tags = tags
        self.comments = comments
    }
}

public extension Article {
    static let mock = Article(
        id: 123456,
        date: Date(timeIntervalSince1970: 1234567890),
        authorId: 123456,
        authorName: "Lorem Ipsum",
        commentsAmount: 69,
        imageUrl: URL(string: "https://i.4pda.ws/s/Zy0hTlz0vbyz2C0NqwmGqhAbhbvNX1nQXZBLeBHoOUajz2n.jpg?v=1719840424")!,
        title: "Enim amet excepteur consectetur quis velit id labore eiusmod.",
        description: "Occaecat enim duis dolor tempor nostrud ea veniam culpa magna incididunt nisi ut laborum amet. Commodo nulla Lorem cupidatat consectetur eu eu commodo.",
        attachments: [],
        tags: [],
        comments: []
    )
}
