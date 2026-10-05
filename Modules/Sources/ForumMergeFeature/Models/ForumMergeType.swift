//
//  ForumMergeType.swift
//  ForPDA
//
//  Created by Xialtal on 30.09.26.
//

import Foundation
import Models

public enum ForumMergeType: Equatable {
    case topics([TopicInfo])
    case posts([SimplifiedPost])
    
    public struct SimplifiedPost: Equatable {
        public let id: Int
        public let authorId: Int
        public let authorName: String
        public let createdAt: Date
        
        public init(id: Int, authorId: Int, authorName: String, createdAt: Date) {
            self.id = id
            self.authorId = authorId
            self.authorName = authorName
            self.createdAt = createdAt
        }
    }
}

