//
//  PreviewResponse.swift
//  ForPDA
//
//  Created by Xialtal on 27.02.26.
//

public struct PreviewResponse: Sendable {
    public let content: String
    public let attachments: [Attachment]
    
    public init(
        content: String,
        attachments: [Attachment]
    ) {
        self.content = content
        self.attachments = attachments
    }
}
