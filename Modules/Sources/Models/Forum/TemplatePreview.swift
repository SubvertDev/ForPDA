//
//  TemplatePreview.swift
//  ForPDA
//
//  Created by Xialtal on 23.02.26.
//

public struct TemplatePreview: Sendable {
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
