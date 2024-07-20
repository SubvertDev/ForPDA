//
//  Attachment.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation

public struct Attachment: Sendable, Hashable {
    public let id: Int
    public let smallUrl: URL
    public let width: Int
    public let height: Int
    public let description: String
    public let fullUrl: URL?
    
    public init(
        id: Int,
        smallUrl: URL,
        width: Int,
        height: Int,
        description: String,
        fullUrl: URL?
    ) {
        self.id = id
        self.smallUrl = smallUrl
        self.width = width
        self.height = height
        self.description = description
        self.fullUrl = fullUrl
    }
}
