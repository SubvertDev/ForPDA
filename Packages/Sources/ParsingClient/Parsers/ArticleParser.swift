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
    6. 80 - flag ?
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
                
                let pollFields = fields.count > 16 ? fields[16] as! [[Any]] : []
                
                return Article(
                    id: fields[2] as! Int,
                    date: Date(timeIntervalSince1970: fields[3] as! TimeInterval),
                    flag: fields[6] as! Int,
                    authorId: fields[7] as! Int,
                    authorName: (fields[8] as! String).convertHtmlCodes(),
                    commentsAmount: fields[9] as! Int,
                    imageUrl: URL(string: (fields[10] as! String))!,
                    title: (fields[11] as! String).convertHtmlCodes(),
                    description: (fields[12] as! String).convertHtmlCodes(),
                    attachments: extractAttachments(from: fields[13] as! [[Any]]),
                    tags: extractTags(from: fields[14] as! [[Any]]),
                    comments: extractComments(from: fields[15] as! [[Any]]),
                    poll: extractPoll(from: pollFields)
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
    2. 0 - normal/deleted/edited/hidden
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
                flag: fields[2] as! Int,
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
        
        let intermediateComments = comments.map { IntermediateComment.from($0) }
        let nested = nestComments(intermediateComments)
        let flattened = flattenComments(nested)
        
        var result: [Comment] = []
        for (intermediate, level) in flattened {
            if var comment = comments.first(where: { $0.id == intermediate.id}) {
                comment.nestLevel = level
                result.append(comment)
            }
        }
        
        return result
    }
    
    private static func extractPoll(from array: [[Any]]) -> ArticlePoll? {
        guard !array.isEmpty else { return nil }
        return ArticlePoll(
            id: array[0][0] as! Int,
            title: array[0][1] as! String,
            flag: array[0][2] as! Int,
            totalVotes: array[0][3] as! Int,
            options: (array[0][4] as! [[Any]]).map {
                ArticlePoll.Option(
                    id: $0[0] as! Int,
                    text: $0[1] as! String,
                    votes: $0[2] as! Int
                )
            }
        )
    }
    
    struct IntermediateComment {
        let id: Int
        let parentId: Int
        let childIds: [Int]
        var children: [IntermediateComment]
        
        static func from(_ comment: Comment) -> IntermediateComment {
            return IntermediateComment(
                id: comment.id,
                parentId: comment.parentId,
                childIds: comment.childIds,
                children: []
            )
        }
    }
    
    private static func nestComments(_ comments: [IntermediateComment]) -> [IntermediateComment] {
        // Create a dictionary to quickly access comments by ID
        var commentMap = [Int: IntermediateComment]()
        for comment in comments {
            commentMap[comment.id] = comment
        }
        
        // Helper function to build children recursively
        func buildChildren(for comment: inout IntermediateComment) {
            // For each childId, retrieve the child from the map, build its children, and append it
            for childId in comment.childIds {
                if var childComment = commentMap[childId] {
                    buildChildren(for: &childComment) // Recursively build the child's children
                    comment.children.append(childComment) // Append the built child
                }
            }
        }
        
        // Step 2: Build the tree structure, starting from the root comments
        var result: [IntermediateComment] = []
        
        for comment in comments {
            if comment.parentId == 0 {
                // This is a root comment, so we build its children recursively
                var rootComment = commentMap[comment.id]!
                buildChildren(for: &rootComment)
                result.append(rootComment) // Append the fully built root comment
            }
        }
        
        return result
    }

    private static func flattenComments(_ comments: [IntermediateComment], level: Int = 0) -> [(comment: IntermediateComment, level: Int)] {
        var result: [(IntermediateComment, Int)] = []
        
        for comment in comments {
            result.append((comment, level)) // Add the current comment with its nesting level
            result.append(contentsOf: flattenComments(comment.children, level: level + 1)) // Recursively flatten and add the children with incremented level
        }
        
        return result
    }
}
