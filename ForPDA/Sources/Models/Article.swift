//
//  Article.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import Foundation

struct Article {
    let url: String
    var info: ArticleInfo?
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
