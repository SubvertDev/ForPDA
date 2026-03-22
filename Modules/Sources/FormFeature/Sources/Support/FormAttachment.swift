//
//  FormAttachment.swift
//  ForPDA
//
//  Created by Xialtal on 27.02.26.
//

import Models

public struct FormAttachment: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let type: Attachment.AttachmentType
    
    public init(
        id: Int,
        name: String,
        type: Attachment.AttachmentType
    ) {
        self.id = id
        self.name = name
        self.type = type
    }
}
