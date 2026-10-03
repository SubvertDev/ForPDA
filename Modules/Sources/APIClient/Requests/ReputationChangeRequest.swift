//
//  ReputationChangeRequest.swift
//  ForPDA
//
//  Created by Xialtal on 12.06.25.
//

import PDAPI
import Models

public struct ReputationChangeRequest: Sendable {
    public let userId: Int
    public let contentType: ReputationChangeContentType
    public let reason: String
    public let action: ReputationChangeActionType
    
    nonisolated var transferVoteType: MemberReputationRequest.ActionType {
        switch action {
        case .up:   .plus
        case .down: .minus
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
        contentType: ReputationChangeContentType,
        reason: String,
        action: ReputationChangeActionType
    ) {
        self.userId = userId
        self.contentType = contentType
        self.reason = reason
        self.action = action
    }
}
