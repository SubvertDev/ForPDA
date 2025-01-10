//
//  JumpForumRequest.swift
//  ForPDA
//
//  Created by Xialtal on 9.01.25.
//

import Foundation
import PDAPI

public struct JumpForumRequest {
    public let postId: Int
    public let topicId: Int
    public let allPosts: Bool
    public let type: ForumJumpType
    
    nonisolated(unsafe) public var transferType: ForumJumpRequest.JumpType {
        switch type {
        case .last: return .last
        case .new: return .new
        case .post: return .post
        }
    }
    
    public init(
        postId: Int,
        topicId: Int,
        allPosts: Bool,
        type: ForumJumpType
    ) {
        self.postId = postId
        self.topicId = topicId
        self.allPosts = allPosts
        self.type = type
    }
    
    public enum ForumJumpType {
        case new
        case last
        case post
    }
}
