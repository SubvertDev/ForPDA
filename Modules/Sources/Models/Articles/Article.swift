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
        return flag & 4 == 0
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
        description: "Occaecat enim duis dolor tempor nostrud ea veniam culpa magna incididunt nisi ut laborum amet.\n\n Игру можно [url=\"https://store.epicgames.com/ru/p/fist-forged-in-shadow-torch\"]забрать бесплатно[/url] до 1 августа.&nbsp;\n\n [quote] «Шесть лет назад Легион захватил и колонизировал город Светоч.\n\n [/quote]\n[center][attachment=\"1:dummy\"][/center]\n\n[center][attachment=\"1:dummy\"] [spoiler=\"ещё 9 фотографий\"][attachment=\"2:dummy\"] [attachment=\"3:dummy\"] [attachment=\"4:dummy\"] [attachment=\"5:dummy\"] [attachment=\"6:dummy\"] [attachment=\"7:dummy\"] [attachment=\"8:dummy\"] [attachment=\"9:dummy\"] [attachment=\"10:dummy\"] [/spoiler][/center]\n\n[center][youtube=eOqif3M_UFY:640:360:::0][/center]\n\n[list]\t[*]41 мм, GPS — $249\n\t[*]41 мм, LTE (или 5G) — $299\n\t[*]45 мм, GPS — $279\n\t[*]45 мм, LTE (или 5G) — $329\n [/list]\n",
        attachments: [
            Attachment(id: 1, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 269, url: URL(string: "https://4pda.to/static/img/news/60/601868t.jpg")!, fullUrl: URL(string: "https://4pda.to/static/img/news/60/601868.jpg")!), downloadCount: nil),
            Attachment(id: 2, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 269, url: URL(string: "https://i.4pda.ws/static/img/news/63/633614t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633614t.jpg")!), downloadCount: nil),
            Attachment(id: 3, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 269, url: URL(string: "https://i.4pda.ws/static/img/news/63/633619t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633619.jpg")!), downloadCount: nil),
            Attachment(id: 4, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 269, url: URL(string: "https://i.4pda.ws/static/img/news/63/633611t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633611.jpg")!), downloadCount: nil),
            Attachment(id: 5, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 269, url: URL(string: "https://i.4pda.ws/static/img/news/63/633612t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633612.jpg")!), downloadCount: nil),
            Attachment(id: 6, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 269, url: URL(string: "https://i.4pda.ws/static/img/news/63/633615t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633615.jpg")!), downloadCount: nil),
            Attachment(id: 7, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 270, url: URL(string: "https://i.4pda.ws/static/img/news/63/633617t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633617.jpg")!), downloadCount: nil),
            Attachment(id: 8, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 270, url: URL(string: "https://i.4pda.ws/static/img/news/63/633618t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633618.jpg")!), downloadCount: nil),
            Attachment(id: 9, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 270, url: URL(string: "https://i.4pda.ws/static/img/news/63/633616t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633616.jpg")!), downloadCount: nil),
            Attachment(id: 10, type: .image, name: "", size: 0, metadata: .init(width: 480, height: 270, url: URL(string: "https://i.4pda.ws/static/img/news/63/633613t.jpg")!, fullUrl: URL(string: "https://i.4pda.ws/static/img/news/63/633613.jpg")!), downloadCount: nil),
        ],
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
