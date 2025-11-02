//
//  QMSMessage.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation

public struct QMSMessage: Sendable, Codable, Hashable, Identifiable {
    
    public struct Attachment: Sendable, Codable, Hashable, Identifiable {
        public let id: Int
        public let flag: Int
        public let name: String
        public let size: Int
        public let downloadsCount: Int
        
        public init(
            id: Int,
            flag: Int,
            name: String,
            size: Int,
            downloadsCount: Int
        ) {
            self.id = id
            self.flag = flag
            self.name = name
            self.size = size
            self.downloadsCount = downloadsCount
        }
    }
    
    public let id: Int
    public let senderId: Int
    public let date: Date
    public let text: String
    public let attachments: [Attachment]
    
    public var processedText: String {
        if attachments.isEmpty {
            return text
        } else {
            var attachmentsText = ""
            for (index, attachment) in attachments.enumerated() {
                attachmentsText.append("[attachment=\(attachment.name),\(attachment.id)]")
                if index != attachments.count - 1 {
                    attachmentsText.append("\n\n")
                }
            }
            return attachmentsText + (text.isEmpty ? "" : "\n\n\(text)")
        }
    }
    
    public init(
        id: Int,
        senderId: Int,
        date: Date,
        text: String,
        attachments: [Attachment]
    ) {
        self.id = id
        self.senderId = senderId
        self.date = date
        self.text = text
        self.attachments = attachments
    }
}
