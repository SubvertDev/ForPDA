//
//  ArticlesListParser.swift
//
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation
import Models

public struct ArticlesListParser {
    
    // MARK: - Articles List
    
    public static func parse(from string: String) throws -> [ArticlePreview] {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let rawArticles = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return try parseArticlePreviews(rawArticles)
    }
    
    // MARK: - Previews Parsing
    
    private static func parseArticlePreviews(_ rawArticles: [[Any]]) throws(ParsingError) -> [ArticlePreview] {
        var articles: [ArticlePreview] = []
        
        for article in rawArticles {
            articles.append(try parseArticlePreview(article))
        }
        
        return articles
    }
    
    // MARK: - Preview Parsing
    
    internal static func parseArticlePreview(_ article: [Any]) throws(ParsingError) -> ArticlePreview {
        guard let id = article[safe: 0] as? Int,
              let date = article[safe: 1] as? TimeInterval,
              let authorId = article[safe: 5] as? Int,
              let authorName = article[safe: 6] as? String,
              let commentsAmount = article[safe: 7] as? Int,
              let imageUrl = article[safe: 8] as? String,
              let title = article[safe: 9] as? String,
              let description = article[safe: 10] as? String,
              let rawTags = article[safe: 11] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return ArticlePreview(
            id: id,
            date: Date(timeIntervalSince1970: date),
            authorId: authorId,
            authorName: authorName,
            commentsAmount: commentsAmount,
            imageUrl: URL(string: imageUrl)!,
            title: title.convertHtmlCodes().convertLinks(),
            description: description.convertHtmlCodes().convertLinks(),
            tags: try extractTags(from: rawTags)
        )
    }
    
    // MARK: - Helpers
    
    private static func extractTags(from array: [[Any]]) throws(ParsingError) -> [Tag] {
        var tags: [Tag] = []
        for tag in array {
            guard let id = tag[safe: 0] as? Int,
                  let name = tag[safe: 1] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            tags.append(Tag(id: id, name: name))
        }
        return tags
    }
}

fileprivate extension String {
    func convertLinks() -> String {
        var cleanedString = self
        if self.contains("[url=") {
            let pattern = #/\[url=.*?\]/#
            cleanedString = cleanedString
                .replacing(pattern, with: "")
                .replacingOccurrences(of: "[/url]", with: "")
        }
        return cleanedString
    }
}
