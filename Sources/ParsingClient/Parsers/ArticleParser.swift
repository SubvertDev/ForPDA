//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation
import Parsing
import Models

public struct ArticleParser {
    
    public static func parse(from string: String) throws -> Article {
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
            PrefixUpTo("\",[").map { String($0) } //",[],
            "\""
        }

        let attachmentParser = Parse(input: Substring.self) {
            Attachment(
                id: $0,
                smallUrl: $1,
                width: $2,
                height: $3,
                description: $4,
                fullUrl: $5
            )
        } with: {
            "["
            PrefixUpTo(",").map { Int($0)! } // ID
            ",\""
            PrefixUpTo("\",").map { URL(string: String($0))! } // Small URL
            "\","
            PrefixUpTo(",").map { Int($0)! } // Width
            ","
            PrefixUpTo(",").map { Int($0)! } // Height
            ","
            PrefixUpTo(",").map { String($0) } // Description
            ",\""
            PrefixUpTo("\"").map { URL(string: String($0)) } // Full URL (Optional)
            "\""
            "]"
        }
        #warning("Иногда нет full url")

        let attachmentsParser = Parse(input: Substring.self) {
            "["
            Many {
                attachmentParser
            } separator: {
                ","
            }
            "]"
        }

        let commentParser = Parse(input: Substring.self) {
            Comment(
                id: $0,
                timestamp: $1,
                authorId: $2,
                authorName: $3,
                parentId: $4,
                text: $5,
                likesAmount: $6,
                avatarUrl: $7
            )
        } with: {
            "["
            PrefixUpTo(",").map { Int($0)! } // Comment ID
            ","
            PrefixUpTo(",").map { Int($0)! } // Timestamp
            ","
            Skip { PrefixUpTo(",").map { Int($0)! } } // 0?
            ","
            PrefixUpTo(",").map { Int($0)! } // Author ID
            ",\""
            PrefixUpTo("\"").map { String($0) } // Author Name
            "\","
            PrefixUpTo(",").map { Int($0)! } // Parent ID
            ","
            QuotedFieldParser().map { String($0) }
            ","
            PrefixUpTo(",").map { Int($0)! } // Likes Amount
            ",\""
            PrefixUpTo("\"").map { URL(string: String($0)) } // Avatar URL
            "\""
            "]"
        }

        let commentsParser = Parse(input: Substring.self) {
            "["
            Many {
                commentParser
            } separator: {
                ","
            }
            "]"
        }

        let articleParser = Parse(input: Substring.self) {
            Article(
                id: $0,
                timestamp: $1,
                authorId: $2,
                authorName: $3,
                commentsAmount: $4,
                imageUrl: $5,
                title: $6.0,
                description: $6.1,
                attachments: $7,
                tags: $8,
                comments: $9
            )
        } with: {
            "["
            Skip { Prefix { $0 != ","} }
            ","
            Skip { Prefix { $0 != ","} }
            ","
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
            Prefix { $0 != "\"" }.map { URL(string: String($0))! } // Image URL
            "\","
            titleAndDescriptionParser
            ","
            attachmentsParser
            ","
            tagsParser
            ","
            commentsParser
            ",[]" // ?
            "]"
        }

        return try articleParser.parse(string)
    }
}
