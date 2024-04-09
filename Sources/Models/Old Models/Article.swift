//
//  Article.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import Foundation

public struct Article: Identifiable {
    public let url: String
    public var info: ArticleInfo?
    
    public var path: [String] {
        return URL(string: url)?.pathComponents ?? []
    }
    
    // RELEASE: Make UUID instead?
    public var id: String { path.joined() + String(Int.random(in: 0...1000)) }
    
    public init(
        url: String,
        info: ArticleInfo? = nil
    ) {
        self.url = url
        self.info = info
    }
    
    public func toNews() -> News {
        return News(
            url: URL(string: url)!,
            info: NewsInfo(
                title: info!.title,
                description: info!.description,
                imageUrl: info!.imageUrl,
                author: info!.author,
                date: info!.date,
                isReview: info!.isReview,
                commentAmount: info!.commentAmount
            )
        )
    }
}

public struct ArticleInfo {
    public let title: String
    public let description: String
    public let imageUrl: URL
    public let author: String
    public let date: String
    public let isReview: Bool
    public let commentAmount: String
    
    public init(
        title: String,
        description: String,
        imageUrl: URL,
        author: String,
        date: String,
        isReview: Bool,
        commentAmount: String
    ) {
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.author = author
        self.date = date
        self.isReview = isReview
        self.commentAmount = commentAmount
    }
}
