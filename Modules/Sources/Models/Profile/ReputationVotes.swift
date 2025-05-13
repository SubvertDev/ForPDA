//
//  ReputationVotes.swift
//  ForPDA
//
//  Created by Xialtal on 12.04.25.
//

public struct ReputationVotes: Codable, Hashable, Sendable {
    public let votes: [ReputationVote]
    public let votesCount: Int
    
    public init(
        votes: [ReputationVote],
        votesCount: Int
    ) {
        self.votes = votes
        self.votesCount = votesCount
    }
}

public extension ReputationVotes {
    static let mock = ReputationVotes(
        votes: [.mock],
        votesCount: 1
    )
}
