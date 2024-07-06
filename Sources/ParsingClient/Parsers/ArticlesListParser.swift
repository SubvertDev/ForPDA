//
//  ArticlesParser.swift
//
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation
import Parsing
import Models

public struct ArticlesListParser {
    
    public static func parse(from string: String) throws -> [ArticlePreview] {
        let tagParser = Parse(input: Substring.self) {
            Tag(id: $0, name: $1)
        } with: {
            "["
            Prefix { $0 != "," }.map { Int($0)! }
            ","
            Prefix { $0 != "]" }.map(String.init)
            "]"
        }
        
        let tagsParser = Parse(input: Substring.self) {
            "["
            Many {
                tagParser
            } separator: {
                ","
            }
            "]"
        }
        
        let titleAndDescriptionParser = Parse(input: Substring.self) {
            "\""
            PrefixUpTo("\",\"").map { String($0) }
            "\",\""
            PrefixUpTo("\",[").map { cleanUrlCode(from: String($0)) }
            "\""
        }
        
        let articlePreviewParser = Parse(input: Substring.self) {
            ArticlePreview(
                id: $0,
                timestamp: $1,
                authorId: $2,
                authorName: $3,
                commentsAmount: $4,
                imageUrl: $5,
                title: $6.0,
                description: $6.1,
                tags: $7
            )
        } with: {
            "["
            Prefix { $0 != "," }.map { Int($0)! } // ID
            ","
            Prefix { $0 != "," }.map { Int($0)! } // Timestamp
            ","
            Skip { Prefix { $0 != "," } } // 0 ?
            ","
            Skip { Prefix { $0 != "," } } // [] ?
            ","
            Skip { Prefix { $0 != "," } } // 64 ?
            ","
            Prefix { $0 != "," }.map { Int($0)! } // Author ID
            ",\""
            Prefix { $0 != "\"" }.map { String($0) } // Author Name
            "\","
            Prefix { $0 != "," }.map { Int($0)! } // Comments Amount
            ",\""
            Prefix { $0 != "\"" }.map { URL(string: String($0))! }
            "\","
            titleAndDescriptionParser
            ",[],"
            tagsParser
            "]"
        }
        
        let articlesPreviewParser = Parse(input: Substring.self) {
            "["
            Many {
                articlePreviewParser
            } separator: {
                ","
            }
            "]"
        }
        
        let articlesPreviewListParser = Parse(input: Substring.self) {
            "["
            Skip { Prefix(14) }
            ","
            articlesPreviewParser
            "]"
        }
        
        return try articlesPreviewListParser.parse(string)
    }
    
    private static func cleanUrlCode(from string: String) -> String {
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
