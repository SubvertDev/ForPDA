//
//  QMSChat.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation

public struct QMSChat: Sendable, Codable, Hashable, Identifiable {
    public let id: Int
    public let creationDate: Date
    public let lastMessageDate: Date
    public let name: String
    public let partnerId: Int
    public let partnerName: String
    public let flag: Int
    public let avatarUrl: URL?
    public let unknownId1: Int
    public let totalCount: Int
    public let unknownId2: Int
    public let lastMessageId: Int
    public let unreadCount: Int
    public var messages: [QMSMessage]
    
    public init(
        id: Int,
        creationDate: Date,
        lastMessageDate: Date,
        name: String,
        partnerId: Int,
        partnerName: String,
        flag: Int,
        avatarUrl: URL?,
        unknownId1: Int,
        totalCount: Int,
        unknownId2: Int,
        lastMessageId: Int,
        unreadCount: Int,
        messages: [QMSMessage]
    ) {
        self.id = id
        self.creationDate = creationDate
        self.lastMessageDate = lastMessageDate
        self.name = name
        self.partnerId = partnerId
        self.partnerName = partnerName
        self.flag = flag
        self.avatarUrl = avatarUrl
        self.unknownId1 = unknownId1
        self.totalCount = totalCount
        self.unknownId2 = unknownId2
        self.lastMessageId = lastMessageId
        self.unreadCount = unreadCount
        self.messages = messages
    }
}
