//
//  ReputationVotesRequest.swift
//  ForPDA
//
//  Created by Xialtal on 12.04.25.
//

import PDAPI

public struct ReputationVotesRequest: Sendable {
    public let userId: Int
    public let type: VotesType
    public let offset: Int
    public let amount: Int
    
    public init(
        userId: Int,
        type: VotesType,
        offset: Int,
        amount: Int
    ) {
        self.userId = userId
        self.type = type
        self.offset = offset
        self.amount = amount
    }
    
    nonisolated public var transferType: MemberReputationVotesRequest.ReputationList {
        switch type {
        case .to: return .to
        case .from: return .from
        }
    }
    
    public enum VotesType: Sendable {
        case to
        case from
    }
}
