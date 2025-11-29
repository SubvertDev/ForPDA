//
//  JumpTo.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.11.2025.
//

import APIClient

public enum JumpTo: Sendable {
    case unread
    case last
    case post(id: Int)
    case page(Int)
    
    var postId: Int {
        switch self {
        case .unread, .last: return 0
        case .post(let id):  return id
        case .page:          fatalError("Unsupported interaction")
        }
    }
    
    var type: JumpForumRequest.ForumJumpType {
        switch self {
        case .unread: return .new
        case .last:   return .last
        case .post:   return .post
        case .page:   fatalError("Unsupported interaction")
        }
    }
}
