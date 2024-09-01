//
//  Article.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation

public struct ArticlePreview: Sendable, Hashable {
    
    public let id: Int
    public let date: Date
    public let authorId: Int
    public let authorName: String
    public let commentsAmount: Int
    public let imageUrl: URL
    public let title: String
    public var description: String
    public let tags: [Tag]
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
    
    public var url: URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateAsString = formatter.string(from: date)
        // TODO: Single url across the app
        return URL(string: "https://4pda.to/\(dateAsString)/\(id)/")!
    }
    
    public init(
        id: Int,
        date: Date,
        authorId: Int,
        authorName: String,
        commentsAmount: Int,
        imageUrl: URL,
        title: String,
        description: String,
        tags: [Tag]
    ) {
        self.id = id
        self.date = date
        self.authorId = authorId
        self.authorName = authorName
        self.commentsAmount = commentsAmount
        self.imageUrl = imageUrl
        self.title = title
        self.description = description
        self.tags = tags
    }
}

public extension ArticlePreview {
    static let mock = ArticlePreview(
        id: 123456,
        date: Date(timeIntervalSince1970: 1234567890),
        authorId: 123456,
        authorName: "Lorem Ipsum",
        commentsAmount: 69,
        imageUrl: URL(string: "https://i.4pda.ws/s/Zy0hTlz0vbyz2C0NqwmGqhAbhbvNX1nQXZBLeBHoOUajz2n.jpg?v=1719840424")!,
        title: "Enim amet excepteur consectetur quis velit id labore eiusmod.",
        description: "Occaecat enim duis dolor tempor nostrud ea veniam culpa magna incididunt nisi ut laborum amet. Commodo nulla Lorem cupidatat consectetur eu eu commodo.",
        tags: []
    )
    
    static func outerDeeplink(id: Int, imageUrl: URL, title: String) -> ArticlePreview {
        return ArticlePreview(id: id, date: .default, authorId: 0, authorName: "", commentsAmount: 0, imageUrl: imageUrl, title: title, description: "", tags: [])
    }
    
    static func innerDeeplink(id: Int) -> ArticlePreview {
        return ArticlePreview(id: id, date: .default, authorId: 0, authorName: "", commentsAmount: 0, imageUrl: URL(string: "/")!, title: "", description: "", tags: [])
    }
    
    static func makeFromArticle(_ article: Article) -> ArticlePreview {
        return ArticlePreview(id: article.id, date: article.date, authorId: article.authorId, authorName: article.authorName, commentsAmount: article.commentsAmount, imageUrl: article.imageUrl, title: article.title, description: article.description, tags: article.tags)
    }
}

public extension Date {
    static let `default` = Date(timeIntervalSince1970: 1720343745)
}
