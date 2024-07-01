//
//  Article.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation
import Parsing

public struct Comment: Hashable {
    public let id: Int
    public let timestamp: Int
    public let authorId: Int
    public let authorName: String
    public let parentId: Int
    public let text: String
    public let likesAmount: Int
    public let avatarUrl: URL?
}

public struct Attachment: Hashable {
    public let id: Int
    public let smallUrl: URL
    public let width: Int
    public let height: Int
    public let fullUrl: URL
}

public struct Article: Hashable {

    public let id: Int
    public let timestamp: Int
    public let authorId: Int
    public let authorName: String
    public let commentsAmount: Int
    public let imageUrl: URL
    public let title: String
    public let description: String
    public let attachments: [Attachment]
    public let tags: [Tag]
    public let comments: [Comment]
    
    public init(
        id: Int,
        timestamp: Int,
        authorId: Int,
        authorName: String,
        commentsAmount: Int,
        imageUrl: URL,
        title: String,
        description: String,
        attachments: [Attachment],
        tags: [Tag],
        comments: [Comment]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.authorId = authorId
        self.authorName = authorName
        self.commentsAmount = commentsAmount
        self.imageUrl = imageUrl
        self.title = title
        self.description = description
        self.attachments = attachments
        self.tags = tags
        self.comments = comments
    }

    #warning("Вынести парсер")
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

//        let urlParser = Parse(input: Substring.self) {
//            Prefix { $0 != "[" }.map { String($0) }
//            "[url=\\\""
//            Prefix { $0 != "\\" }.map { ("https:" + $0) }
//            "\\\"]"
//            Prefix { $0 != "[" }
//            "[/url]"
//            Prefix { $0 != "\""}.map { String($0) }
//            "\""
//        }

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
                fullUrl: $4
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
            ",\"\",\"" // ?
            PrefixUpTo("\"").map { URL(string: String($0))! } // Full URL
            "\""
            "]"
        }

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

public struct QuotedFieldParser: ParserPrinter {

    enum FieldError: Error {
        case unimplemented
        case logicError
        case malformed
    }

    enum ParsingState {
        case notStarted
        case midField
    }

    public init() {}

    public func parse(_ input: inout Substring) throws -> Substring {
        var result = Substring()
        var state = ParsingState.notStarted
        var quoteCount = 0

        while let character = input.first {
            input.removeFirst()
            switch state {
            case .notStarted:
                guard character == "\"" else { throw FieldError.malformed }
                state = .midField
                quoteCount += 1

            case .midField:
                if character == "\"" {
                    if input.isEmpty {
                        if quoteCount % 2 == 0 {
                            throw FieldError.malformed
                        } else {
                            return result //.utf8
                        }
                    } else {
                        quoteCount += 1
                        result.append(character)
                        if let first = input.first { // Временный хак, лучше не придумал
                            let secondIndex = input.index(after: input.startIndex)
                            let second = input[secondIndex]
                            if first == "," && second.isNumber {
                                return result
                            }
                        }
                    }
                } else {
                    result.append(character)
                }
            }
        }
        throw FieldError.malformed
    }

    public func print(_ output: Substring, into input: inout Substring) throws { }
}
