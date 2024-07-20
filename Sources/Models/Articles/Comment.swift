//
//  Comment.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation

public struct Comment: Hashable {
    public let id: Int
    public let date: Date
    public let authorId: Int
    public let authorName: String
    public let parentId: Int
    public let text: String
    public let likesAmount: Int
    public let avatarUrl: URL?
    
    public init(
        id: Int,
        date: Date,
        authorId: Int,
        authorName: String,
        parentId: Int,
        text: String,
        likesAmount: Int,
        avatarUrl: URL?
    ) {
        self.id = id
        self.date = date
        self.authorId = authorId
        self.authorName = authorName
        self.parentId = parentId
        self.text = text
        self.likesAmount = likesAmount
        self.avatarUrl = avatarUrl
    }
}
