//
//  QMSMessage.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation

public struct QMSMessage: Sendable, Codable, Hashable, Identifiable {
    public let id: Int
    public let senderId: Int
    public let date: Date
    public let text: String
    // public let attachments: [QMSAttachment]
    
    public init(
        id: Int,
        senderId: Int,
        date: Date,
        text: String
    ) {
        self.id = id
        self.senderId = senderId
        self.date = date
        self.text = text
    }
}
