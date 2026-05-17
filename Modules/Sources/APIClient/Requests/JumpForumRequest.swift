//
//  JumpForumRequest.swift
//  ForPDA
//
//  Created by Xialtal on 9.01.25.
//

import Foundation
import PDAPI
import Models

public struct JumpForumRequest {
    public let postId: Int
    public let topicId: Int
    public let postsFilter: TopicPostsFilter
    public let type: ForumJumpType
    
    nonisolated public var transferType: ForumJumpRequest.JumpType {
        switch type {
        case .last: return .last
        case .new: return .new
        case .post: return .post
        }
    }
    
    public init(
        postId: Int,
        topicId: Int,
        postsFilter: TopicPostsFilter,
        type: ForumJumpType
    ) {
        self.postId = postId
        self.topicId = topicId
        self.postsFilter = postsFilter
        self.type = type
    }
    
    public enum ForumJumpType {
        case new
        case last
        case post
    }
}
