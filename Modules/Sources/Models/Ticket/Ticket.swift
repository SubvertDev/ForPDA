//
//  Ticket.swift
//  ForPDA
//
//  Created by Xialtal on 3.05.26.
//

import Foundation

public struct Ticket: Sendable {
    public let info: TicketInfo
    public let comments: [Comment]
    
    public struct Comment: Sendable {
        public let id: Int
        public let content: String
        public let authorId: Int
        public let authorName: String
        public let createdAt: Date
        
        public init(
            id: Int,
            content: String,
            authorId: Int,
            authorName: String,
            createdAt: Date
        ) {
            self.id = id
            self.content = content
            self.authorId = authorId
            self.authorName = authorName
            self.createdAt = createdAt
        }
    }
    
    public init(
        info: TicketInfo,
        comments: [Comment]
    ) {
        self.info = info
        self.comments = comments
    }
}

public extension Ticket {
    static let mock = Ticket(
        info: .mock,
        comments: [
            .init(
                id: 0,
                content: "New topic: ForPDA [iOS]. [B]Automatic notification.[/B]",
                authorId: 6176341,
                authorName: "AirFlare",
                createdAt: Date.now
            ),
            .init(
                id: 1,
                content: "Wow, you are [B]genius[/B]!",
                authorId: 3640948,
                authorName: "subvertd",
                createdAt: Date.now
            )
        ]
    )
}
