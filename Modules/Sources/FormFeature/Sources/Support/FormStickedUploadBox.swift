//
//  FormStickedUploadBox.swift
//  ForPDA
//
//  Created by Xialtal on 2.03.26.
//
   
public struct FormStickedUploadBox: Sendable, Equatable {
    public let id: Int
    public let existsAttachments: [FormAttachment]
    public let allowedExtensions: [String]
    
    public init(
        id: Int,
        existsAttachments: [FormAttachment] = [],
        allowedExtensions: [String]
    ) {
        self.id = id
        self.existsAttachments = existsAttachments
        self.allowedExtensions = allowedExtensions
    }
}
