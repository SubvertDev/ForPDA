//
//  Article.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import Foundation

struct Article: Identifiable {
    let url: String
    var info: ArticleInfo?
    
    var path: [String] {
        return URL(string: url)?.pathComponents ?? []
    }
    
    // RELEASE: Make UUID instead?
    var id: String { path.joined() + String(Int.random(in: 0...1000)) }
    
    func toNews() -> News {
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

struct ArticleInfo {
    let title: String
    let description: String
    let imageUrl: URL
    let author: String
    let date: String
    let isReview: Bool
    let commentAmount: String
}
