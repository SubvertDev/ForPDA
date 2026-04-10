//
//  PostKarmaVote.swift
//  ForPDA
//
//  Created by Xialtal on 10.04.26.
//

import Foundation

public struct PostKarmaVote: Sendable, Identifiable {
    public let userId: Int
    public let nickname: String
    public let voteDate: Date
    public let vote: Int
    
    public var id: Int {
        return userId
    }
    
    public init(
        userId: Int,
        nickname: String,
        voteDate: Date,
        vote: Int
    ) {
        self.userId = userId
        self.nickname = nickname
        self.voteDate = voteDate
        self.vote = vote
    }
}

public extension Array where Array == Array<PostKarmaVote> {
    static let mock: [PostKarmaVote] = [
        .init(
            userId: 6176341,
            nickname: "AirFlare",
            voteDate: Date.now,
            vote: 1
        ),
        .init(
            userId: 3640948,
            nickname: "subvertd",
            voteDate: Date.now,
            vote: 1
        ),
        .init(
            userId: 16072016,
            nickname: "Abracadabra",
            voteDate: Date(timeIntervalSince1970: 1703656574),
            vote: -1
        ),
        .init(
            userId: 15072016,
            nickname: "Lia",
            voteDate: Date(timeIntervalSince1970: 1503656574),
            vote: -1
        ),
        .init(
            userId: 14072016,
            nickname: "FocusPokus",
            voteDate: Date(timeIntervalSince1970: 1603656574),
            vote: +2
        ),
    ]
}
