//
//  PostPreview.swift
//  ForPDA
//
//  Created by Xialtal on 15.03.25.
//

public struct PostPreview: Sendable {
    public let content: String
    public let attachmentIds: [Int]
    
    public init(
        content: String,
        attachmentIds: [Int]
    ) {
        self.content = content
        self.attachmentIds = attachmentIds
    }
}
