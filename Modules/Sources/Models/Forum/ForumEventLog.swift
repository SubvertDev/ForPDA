//
//  ForumEventLog.swift
//  ForPDA
//
//  Created by Xialtal on 14.05.26.
//

import Foundation

public struct ForumEventLog: Sendable {
    public let userId: Int
    public let userName: String
    public let userGroup: User.Group
    public let content: String
    public let createdAt: Date
    
    public init(
        userId: Int,
        userName: String,
        userGroup: User.Group,
        content: String,
        createdAt: Date
    ) {
        self.userId = userId
        self.userName = userName
        self.userGroup = userGroup
        self.content = content
        self.createdAt = createdAt
    }
}

public extension Array where Array == [ForumEventLog] {
    static let mockPost: [ForumEventLog] = [
        .init(
            userId: 6176341,
            userName: "AirFlare",
            userGroup: .regular,
            content: "Post changed: old name: ForPDA One Love",
            createdAt: Date.now
        ),
        .init(
            userId: 6176341,
            userName: "AirFlare",
            userGroup: .regular,
            content: "Post hidden: ([url=\"https://4pda.to/forum/index.php?showtopic=1104159&view=findpost&p=139696274\"]139696274[/url])",
            createdAt: Date.now - 17
        )
    ]
    
    static let mockTopic: [ForumEventLog] = [
        .init(
            userId: 6176341,
            userName: "AirFlare",
            userGroup: .regular,
            content: "Topic changed: old name: ForPDA [iOS]",
            createdAt: Date.now
        ),
        .init(
            userId: 6176341,
            userName: "AirFlare",
            userGroup: .regular,
            content: "Post pinned: ([url=\"https://4pda.to/forum/index.php?showtopic=1104159&view=findpost&p=139696274\"]139696274[/url])",
            createdAt: Date.now - 17
        )
    ]
}
