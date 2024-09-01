//
//  ArticleParser.swift
//
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation
import Models
import OSLog

public struct ArticleParser {
    
    /**
    0. 68111 - atomic
    1. 0 - ???
    2. 429778 - id
    3. 1720354500 - timestamp
    4. 0 - ???
    5. [] - ???
    6. 64 - ???
    7. 11029883 - author id
    8. "Оксана Рубко" - author name
    9. 0 - comments amount
    10. "https..." - image url
    11. "title" - title
    12. "description" - description
    13. [attachment] - attachments
    14. [tag] - tags
    15. [comment] - comments
    16. [] - ???
    */
    public static func parse(from string: String) throws -> Article {
        if let data = string.data(using: .utf8) {
            do {
                guard let fields = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                    throw ParsingError.failedToCastDataToAny
                }
                
                return Article(
                    id: fields[2] as! Int,
                    date: Date(timeIntervalSince1970: fields[3] as! TimeInterval),
                    authorId: fields[7] as! Int,
                    authorName: (fields[8] as! String).convertHtmlCodes(),
                    commentsAmount: fields[9] as! Int,
                    imageUrl: URL(string: (fields[10] as! String))!,
                    title: (fields[11] as! String).convertHtmlCodes(),
                    description: (fields[12] as! String).convertHtmlCodes(),
                    attachments: extractAttachments(from: fields[13] as! [[Any]]),
                    tags: extractTags(from: fields[14] as! [[Any]]),
                    comments: extractComments(from: fields[15] as! [[Any]])
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    // MARK: - Helpers
    
    /**
    0. 1 - id
    1. "https..." - small image url
    2. 480 - width
    3. 300 - height
    4. "description" - description
    5. "https..." - (optional) full image url
    */
    private static func extractAttachments(from array: [[Any]]) -> [Attachment] {
        return array.map { fields in
            return Attachment(
                id: fields[0] as! Int,
                smallUrl: URL(string: fields[1] as! String)!,
                width: fields[2] as! Int,
                height: fields[3] as! Int,
                description: fields[4] as! String,
                fullUrl: URL(string: fields[5] as! String)
            )
        }
    }
    
    /**
    0. 24540 - id
    1. "!!технологии" - name
    */
    private static func extractTags(from array: [[Any]]) -> [Tag] {
        return array.map { fields in
            return Tag(
                id: fields[0] as! Int,
                name: fields[1] as! String
            )
        }
    }
    
    /**
    0. 9425129 - id
    1. 1720355277 - date
    2. 0 - ???
    3. 11393353 - author id
    4. "name" - author name
    5. 9425113 - parent id
    6. "text" - text
    7. 0 - likes amount
    8. "https..." - (optional) avatar url
    */
    private static func extractComments(from array: [[Any]]) -> [Comment] {
        var comments: [Comment] = array.compactMap { fields in
            // Fix for some "[0]" aka empty comments
            if fields.count < 9 {
                // TODO: Add oslog
                print("[WARNING] Found empty comment, skipping iteration...")
                return nil
            }
            return Comment(
                id: fields[0] as! Int,
                date: Date(timeIntervalSince1970: fields[1] as! TimeInterval),
                type: CommentType(rawValue: fields[2] as! Int) ?? .normal,
                authorId: fields[3] as! Int,
                authorName: (fields[4] as! String).convertHtmlCodes(),
                parentId: fields[5] as! Int,
                childIds: [],
                text: (fields[6] as! String).convertHtmlCodes(),
                likesAmount: fields[7] as! Int,
                avatarUrl: URL(string: fields[8] as! String)
            )
        }
        
        for (index, comment) in comments.enumerated() {
            comments[index].childIds = comments.filter { $0.parentId == comment.id }.map { $0.id }
        }
        
        return comments
    }
}
