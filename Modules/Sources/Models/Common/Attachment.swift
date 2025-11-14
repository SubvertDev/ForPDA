//
//  Attachment.swift
//  ForPDA
//
//  Created by Xialtal on 14.11.25.
//

import Foundation

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
        public let fullUrl: URL?
        public let width: Int
        public let height: Int
        public let description: String
        
        public init(
            width: Int,
            height: Int,
            url: URL,
            fullUrl: URL? = nil,
            description: String = ""
        ) {
            self.url = url
            self.fullUrl = fullUrl
            self.width = width
            self.height = height
            self.description = description
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
