//
//  TopicEditRequest.swift
//  ForPDA
//
//  Created by Xialtal on 29.03.26.
//

import Models

public struct TopicEditRequest {
    public let id: Int
    public let title: String
    public let description: String
    public let poll: PDAPIDocument
    
    public init(
        id: Int,
        title: String,
        description: String,
        poll: PDAPIDocument
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.poll = poll
    }
}
