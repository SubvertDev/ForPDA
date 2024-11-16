//
//  Unread.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.11.2024.
//

import Foundation

public struct Unread: Codable, Sendable, Hashable {
    public let date: Date
    public let unreadCount: Int
    public let qms: [QMS]
    
    public init(
        date: Date,
        unreadCount: Int,
        qms: [QMS]
    ) {
        self.date = date
        self.unreadCount = unreadCount
        self.qms = qms
    }
    
    public struct QMS: Codable, Sendable, Hashable {
        public let dialogId: Int
        public let dialogName: String
        public let partnerId: Int
        public let partnerName: String
        public let lastMessageId: Int
        public let unreadCount: Int
        
        public init(
            dialogId: Int,
            dialogName: String,
            partnerId: Int,
            partnerName: String,
            lastMessageId: Int,
            unreadCount: Int
        ) {
            self.dialogId = dialogId
            self.dialogName = dialogName
            self.partnerId = partnerId
            self.partnerName = partnerName
            self.lastMessageId = lastMessageId
            self.unreadCount = unreadCount
        }
    }
}
