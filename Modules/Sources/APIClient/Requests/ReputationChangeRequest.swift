//
//  ReputationChangeRequest.swift
//  ForPDA
//
//  Created by Xialtal on 12.06.25.
//

import PDAPI

public struct ReputationChangeRequest: Sendable {
    public let userId: Int
    public let contentType: ContentType
    public let reason: String
    public let action: ChangeActionType
    
    public enum ContentType: Sendable, Equatable {
        case post(id: Int)
        case comment(id: Int)
        case profile
    }
    
    public enum ChangeActionType: Sendable {
        case up
        case down
        case delete
        case recover
    }
    
    nonisolated var transferVoteType: MemberReputationRequest.VoteType {
        switch action {
        case .up:   .plus
        case .down: .minus
            
        // TODO: Implement.
        case .delete, .recover: .plus
        }
    }
    
    nonisolated var transferContentType: Int {
        switch contentType {
        case .profile:          0
        case .post(let id):     id
        case .comment(let id): -id
        }
    }
    
    public init(
        userId: Int,
        contentType: ContentType,
        reason: String,
        action: ChangeActionType
    ) {
        self.userId = userId
        self.contentType = contentType
        self.reason = reason
        self.action = action
    }
}
