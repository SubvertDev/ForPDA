//
//  TicketInfo.swift
//  ForPDA
//
//  Created by Xialtal on 3.05.26.
//

import Foundation

public struct TicketInfo: Sendable {
    public let title: String
    public let status: TicketStatus
    public let subjectId: Int
    public let subjectElementId: Int
    public let subjectRootId: Int
    public let subjectRootName: String
    public let authorId: Int
    public let authorName: String
    public let handlerId: Int
    public let handlerName: String
    public let createdAt: Date
    
    public init(
        title: String,
        status: TicketStatus,
        subjectId: Int,
        subjectElementId: Int,
        subjectRootId: Int,
        subjectRootName: String,
        authorId: Int,
        authorName: String,
        handlerId: Int,
        handlerName: String,
        createdAt: Date
    ) {
        self.title = title
        self.status = status
        self.subjectId = subjectId
        self.subjectElementId = subjectElementId
        self.subjectRootId = subjectRootId
        self.subjectRootName = subjectRootName
        self.authorId = authorId
        self.authorName = authorName
        self.handlerId = handlerId
        self.handlerName = handlerName
        self.createdAt = createdAt
    }
}

public extension TicketInfo {
    static let mock = TicketInfo(
        title: "New topic: ForPDA [iOS]",
        status: .processing,
        subjectId: 1104159,
        subjectElementId: 136063497,
        subjectRootId: 140,
        subjectRootName: "iOS - Programs",
        authorId: 6176341,
        authorName: "AirFlare",
        handlerId: 3640948,
        handlerName: "subvertd",
        createdAt: Date.now
    )
}
