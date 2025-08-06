//
//  ReputationVote.swift
//  ForPDA
//
//  Created by Xialtal on 12.04.25.
//

import Foundation
import SFSafeSymbols

public struct ReputationVote: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let flag: Int
    public let toId: Int
    public let toName: String
    public let authorId: Int
    public let authorName: String
    public let reason: String
    public let modified: VoteModified?
    public let createdIn: VoteCreatedIn
    public let createdAt: Date
    public let isDown: Bool
    
    public var title: String {
        switch createdIn {
        case .profile:
            return "From profile"
        case let .topic(_, topicName, _):
            return topicName
        case let .site(_, articleName, _):
            return articleName
        }
    }
    
    public var titleId: Int {
        switch createdIn {
        case .profile:
            return id
        case .topic(let id, _, _):
            return id
        case .site(let id, _, _):
            return id
        }
    }
    
    public var createdInType: String {
        switch createdIn {
        case .profile:
            return "Profile"
        case .topic(_, _, _,):
            return "Topic"
        case .site(_, _, _,):
            return "Article"
        }
    }
    
    
    public var systemSymbol: SFSymbol {
        switch createdIn {
        case .profile:
            return .person
        case .topic:
            // добавить варинат с фигмы для iOS 17
            return .bubbleLeftAndBubbleRight
        case .site:
            return .docPlaintext
        }
    }
    
    public var markLabel: String {
        flag == 1 ? "Raised" : "Lowered"
    }
    
    public var arrowSymbol: SFSymbol {
        if #available(iOS 17.0, *) {
            return flag == 1 ? .arrowshapeUpFill : .arrowshapeDownFill
        } else {
            return flag == 1 ? .arrowUp : .arrowDown
        }
    }
    
    public init(
        id: Int,
        flag: Int,
        toId: Int,
        toName: String,
        authorId: Int,
        authorName: String,
        reason: String,
        modified: VoteModified?,
        createdIn: VoteCreatedIn,
        createdAt: Date,
        isDown: Bool
    ) {
        self.id = id
        self.flag = flag
        self.toId = toId
        self.toName = toName
        self.authorId = authorId
        self.authorName = authorName
        self.reason = reason
        self.modified = modified
        self.createdIn = createdIn
        self.createdAt = createdAt
        self.isDown = isDown
    }
    
    public enum VoteCreatedIn: Codable, Hashable, Sendable {
        case profile
        case topic(id: Int, topicName: String, postId: Int)
        case site(id: Int, articleName: String, commentId: Int)
    }
    
    public struct VoteModified: Codable, Hashable, Sendable {
        public let userId: Int
        public let userName: String
        public let isDenied: Bool
        
        public init(userId: Int, userName: String, isDenied: Bool) {
            self.userId = userId
            self.userName = userName
            self.isDenied = isDenied
        }
    }
}

// MARK: - Mocks

public extension ReputationVote {
    static let mock = ReputationVote(
        id: 1,
        flag: 1,
        toId: 23232,
        toName: "AirFlare",
        authorId: 6176341,
        authorName: "4spader",
        reason: "For fun",
        modified: nil,
        createdIn: .profile,
        createdAt: .now,
        isDown: false
    )
}
