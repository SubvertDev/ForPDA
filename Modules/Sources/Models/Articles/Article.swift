//
//  Article.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation

public struct Article: Sendable, Hashable, Codable {

    public let id: Int
    public let date: Date
    public let flag: Int
    public let authorId: Int
    public let authorName: String
    public let commentsAmount: Int
    public let imageUrl: URL
    public let title: String
    public let description: String
    public let attachments: [Attachment]
    public let tags: [Tag]
    public var comments: [Comment]
    public let poll: ArticlePoll?
    
    public var canComment: Bool {
        return flag & 16 != 0
    }
    public var isExpired: Bool {
        if let expiryDate = Calendar.current.date(byAdding: .day, value: -7, to: date) {
            return date >= expiryDate
        }
        return true
    }
    
    public init(
        id: Int,
        date: Date,
        flag: Int,
        authorId: Int,
        authorName: String,
        commentsAmount: Int,
        imageUrl: URL,
        title: String,
        description: String,
        attachments: [Attachment],
        tags: [Tag],
        comments: [Comment],
        poll: ArticlePoll?
    ) {
        self.id = id
        self.date = date
        self.flag = flag
        self.authorId = authorId
        self.authorName = authorName
        self.commentsAmount = commentsAmount
        self.imageUrl = imageUrl
        self.title = title
        self.description = description
        self.attachments = attachments
        self.tags = tags
        self.comments = comments
        self.poll = poll
    }
}

public extension Article {
    static let mock = Article(
        id: 123456,
        date: Date(timeIntervalSince1970: 1234567890),
        flag: 80,
        authorId: 234567,
        authorName: "Lorem Author",
        commentsAmount: 69,
        imageUrl: URL(string: "https://i.4pda.ws/s/Zy0hTlz0vbyz2C0NqwmGqhAbhbvNX1nQXZBLeBHoOUajz2n.jpg?v=1719840424")!,
        title: "Enim amet excepteur consectetur quis velit id labore eiusmod.",
        description: "Occaecat enim duis dolor tempor nostrud ea veniam culpa magna incididunt nisi ut laborum amet.\n\n Игру можно [url=\"https://store.epicgames.com/ru/p/fist-forged-in-shadow-torch\"]забрать бесплатно[/url] до 1 августа.&nbsp;\n\n [quote] «Шесть лет назад Легион захватил и колонизировал город Светоч.\n\n [/quote]\n[center][attachment=\"1:dummy\"][/center]\n\n[center][youtube=eOqif3M_UFY:640:360:::0][/center]\n\n[list]\t[*]41 мм, GPS — $249\n\t[*]41 мм, LTE (или 5G) — $299\n\t[*]45 мм, GPS — $279\n\t[*]45 мм, LTE (или 5G) — $329\n [/list]\n",
        attachments: [Attachment(id: 1, smallUrl: URL(string: "https://4pda.to/static/img/news/60/601868t.jpg")!, width: 480, height: 270, description: "", fullUrl: URL(string: "https://4pda.to/static/img/news/60/601868.jpg")!)],
        tags: [],
        comments: .mockArray,
        poll: nil
    )
    
    static var mockWithComment: Article {
        var mock = mock
        mock.comments = [
            .mock
        ]
        return mock
    }
    
    static var mockWithTwoComments: Article {
        var mock = mock
        mock.comments = [
            .mock,
            .init(id: 1, date: .now, flag: 0, authorId: 666, authorName: "Tester", parentId: 0, childIds: [], text: "Test text", likesAmount: 0, avatarUrl: nil)
        ]
        return mock
    }
}
