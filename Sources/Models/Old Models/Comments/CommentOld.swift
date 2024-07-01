//
//  CommentOld.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import Foundation

public class CommentOld: AbstractComment, ReflectedStringConvertible, Hashable {
    
    // MARK: - Properties
    
    public let id = UUID().uuidString
    public let avatarUrl: URL?
    public let author: String
    public let text: String
    public let date: String
    public let likes: Int
    
    public var replies: [AbstractComment]!
    public var level: Int!
    public var replyTo: AbstractComment?
    
    // MARK: - Init
    
    public init(
        avatarUrl: URL?,
        author: String,
        text: String,
        date: String,
        likes: Int,
        replies: [AbstractComment]!,
        level: Int!,
        replyTo: AbstractComment? = nil
    ) {
        self.avatarUrl = avatarUrl
        self.author = author
        self.text = text
        self.date = date
        self.likes = likes
        self.replies = replies
        self.level = level
        self.replyTo = replyTo
    }
    
    // MARK: - Static Functions
    
    static func countTotalComments(_ comments: [AbstractComment]) -> Int {
        var totalCount = comments.count
        for comment in comments {
            totalCount += countTotalComments(comment.replies)
        }
        return totalCount
    }
    
    // MARK: - Hashable & Equatable
    
    public static func == (lhs: CommentOld, rhs: CommentOld) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}

// MARK: - ReflectedStringConvertible

protocol ReflectedStringConvertible: CustomStringConvertible { }

extension ReflectedStringConvertible {
    public var description: String {
        let mirror = Mirror(reflecting: self)
        
        var str = "\(mirror.subjectType)("
        var first = true
        for (label, value) in mirror.children {
            if let label = label {
                if first {
                    first = false
                } else {
                    str += ", "
                }
                str += label
                str += ": "
                str += "\(value)"
            }
        }
        str += ")"
        
        return str
    }
}
