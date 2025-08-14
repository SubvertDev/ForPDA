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
    
    private var createdInDetails: (title: String, titleId: Int, createdInType: String, goToId: Int?) {
        switch createdIn {
        case .profile:
            return ("From profile", id, "Profile", nil)
            
        case let .topic(id: id, topicName: topicName, postId: postId):
            return (topicName, id, "Topic", postId)
            
        case .site(let id, let articleName, _):
            return (articleName, id, "Article", nil)
        }
    }
    
    public var title: String {
        createdInDetails.title
    }
    
    public var titleId: Int {
        createdInDetails.titleId
    }
    
    public var createdInType: String {
        createdInDetails.createdInType
    }
    
    public var goToId: Int? {
        createdInDetails.goToId
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
