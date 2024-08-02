//
//  ArticlesListParser.swift
//
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation
import Models

public struct ArticlesListParser {
    
    public static func parse(from string: String) throws -> [ArticlePreview] {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                var articles: [ArticlePreview] = []
                
                for article in array[3] as! [[Any]] {
                    let article = ArticlePreview(
                        id: article[0] as! Int,
                        date: Date(timeIntervalSince1970: article[1] as! TimeInterval),
                        authorId: article[5] as! Int,
                        authorName: article[6] as! String,
                        commentsAmount: article[7] as! Int,
                        imageUrl: URL(string: article[8] as! String)!,
                        title: (article[9] as! String).convertHtmlCodes(),
                        description: clean(string: article[10] as! String),
                        tags: extractTags(from: article[11] as! [[Any]])
                    )
                    articles.append(article)
                }
                
                return articles
                
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    // MARK: - Helpers
    
    private static func extractTags(from array: [[Any]]) -> [Tag] {
        return array.map { Tag(id: $0[0] as! Int, name: $0[1] as! String) }
    }
    
    private static func clean(string: String) -> String {
        var cleanedString = string
        
        if string.contains("[url=") {
            let pattern = #/\[url=.*?\]/#
            cleanedString = cleanedString
                .replacing(pattern, with: "")
                .replacingOccurrences(of: "[/url]", with: "")
        }
        
        cleanedString = cleanedString
            .replacingOccurrences(of: "&nbsp;", with: " ")
        
        return cleanedString
    }
}
