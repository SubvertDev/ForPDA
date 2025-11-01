//
//  Post.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct Post: Sendable, Hashable, Identifiable, Codable {
        
    // MARK: - Properties
    
    public let id: Int
    public let flag: Int
    public let content: String
    public let author: Author
    public let attachments: [Attachment]
    public let createdAt: Date
    public let lastEdit: LastEdit?
    private let rawKarma: Int
    
    public var canEdit: Bool {
        return flag & 128 > 0
    }
    
    public var canDelete: Bool {
        return flag & 256 > 0
    }
    
    public var karma: Int {
        return rawKarma >> 3
    }
    
    public var canChangeKarma: Bool {
        if rawKarma & 1 > 0 {
            rawKarma & 2 <= 0
        } else { false }
    }
    
    public var imageAttachmentsOrdered: [Attachment] {
        let numberRegex = /(\d+)/
        let extractedNumbers = content
            .matches(of: numberRegex)
            .compactMap { Int($0.1) }
        
        var orderedAttachments = extractedNumbers.compactMap { number in
            attachments.first(where: { $0.id == number })
        }
        
        if !content.contains("attachment") || orderedAttachments.count < attachments.filter({ isImageAttachment($0) }).count {
            orderedAttachments = Array(Set(orderedAttachments + attachments))
        }
        
        return orderedAttachments
            .filter { isImageAttachment($0) }
    }
    
    // MARK: - Init
    
    public init(
        id: Int,
        flag: Int,
        content: String,
        author: Author,
        karma: Int,
        attachments: [Attachment],
        createdAt: Date,
        lastEdit: LastEdit?
    ) {
        self.id = id
        self.flag = flag
        self.content = content
        self.author = author
        self.rawKarma = karma
        self.attachments = attachments
        self.createdAt = createdAt
        self.lastEdit = lastEdit
    }
    
    // MARK: - Nested Structs
    
    public struct Attachment: Sendable, Hashable, Codable {
        public let id: Int
        public let type: AttachmentType
        public let name: String
        public let size: Int
        public let metadata: Metadata?
        public let downloadCount: Int?
        
        public var sizeString: String {
            let units = ["Б", "КБ", "МБ", "ГБ"]
            var size = Double(size)
            var unitIndex = 0
            
            while size >= 1024 && unitIndex < units.count - 1 {
                size /= 1024
                unitIndex += 1
            }
            
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = (size.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 1
            formatter.numberStyle = .decimal
            
            let formattedSize = formatter.string(from: NSNumber(value: size)) ?? "\(size)"
            return "\(formattedSize) \(units[unitIndex])"
        }
        
        public enum AttachmentType: Int, Sendable, Hashable, Codable {
            case file = 0
            case image = 1
        }
        
        public struct Metadata: Sendable, Hashable, Codable {
            public let url: URL
            public let width: Int
            public let height: Int
            
            public init(width: Int, height: Int, url: URL) {
                self.url = url
                self.width = width
                self.height = height
            }
        }
        
        public init(
            id: Int,
            type: AttachmentType,
            name: String,
            size: Int,
            metadata: Metadata?,
            downloadCount: Int?
        ) {
            self.id = id
            self.type = type
            self.name = name
            self.size = size
            self.metadata = metadata
            self.downloadCount = downloadCount
        }
    }
    
    public struct LastEdit: Sendable, Hashable, Codable {
        public let userId: Int
        public let username: String
        public let reason: String
        public let date: Date
        
        public init(userId: Int, username: String, reason: String, date: Date) {
            self.userId = userId
            self.username = username
            self.reason = reason
            self.date = date
        }
    }
    
    public struct Author: Sendable, Hashable, Codable {
        public let id: Int
        public let name: String
        public let groupId: Int
        public let avatarUrl: String
        public let lastSeenDate: Date
        public let signature: String
        public let reputationCount: Int
        
        public init(
            id: Int,
            name: String,
            groupId: Int,
            avatarUrl: String,
            lastSeenDate: Date,
            signature: String,
            reputationCount: Int
        ) {
            self.id = id
            self.name = name
            self.groupId = groupId
            self.avatarUrl = avatarUrl
            self.lastSeenDate = lastSeenDate
            self.signature = signature
            self.reputationCount = reputationCount
        }
    }
    
    // MARK: - Private
    
    private func isImageAttachment(_ attachment: Attachment) -> Bool {
        return attachment.type == .image && attachment.metadata != nil && attachment.size != 0
    }
}

// MARK: - Mocks

extension Post {
    static func mock(id: Int = 0) -> Post {
        return Post(
            id: id,
            flag: 384,
            content: "[snapback]123[/snapback], Lorem ipsum...\n[font=fontello]4[/font]",
            author: Author(
                id: 6176341,
                name: "AirFlare",
                groupId: 8,
                avatarUrl: "https://4pda.to/s/Zy0hVVliEZZvbylgfQy11QiIjvDIhLJBjheakj4yIz2ohhN2F.jpg",
                lastSeenDate: Date(timeIntervalSince1970: 1725706883),
                signature: "",
                reputationCount: 312
            ),
            karma: 1,
            attachments: [
                Attachment(
                    id: 14308454,
                    type: .image,
                    name: "IMG_2369.png",
                    size: 62246,
                    metadata: Attachment.Metadata(
                        width: 281,
                        height: 500,
                        url: URL(string: "https://cs2c9f.4pda.ws/14308454.png")!
                    ),
                    downloadCount: nil
                )
            ],
            createdAt: Date(timeIntervalSince1970: 1725706321),
            lastEdit: LastEdit(
                userId: 6176341,
                username: "AirFlare",
                reason: "for fun",
                date: Date(timeIntervalSince1970: 1725706883)
            )
        )
    }
}
