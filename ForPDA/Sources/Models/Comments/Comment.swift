//
//  Comment.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import Foundation

class Comment: AbstractComment, ReflectedStringConvertible {
    let avatarUrl: String
    let author: String
    let text: String
    let date: String
    let likes: Int
    
    var replies: [AbstractComment]!
    var level: Int!
    var replyTo: AbstractComment?
    
    init(
        avatarUrl: String,
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
}

public protocol ReflectedStringConvertible: CustomStringConvertible { }

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
