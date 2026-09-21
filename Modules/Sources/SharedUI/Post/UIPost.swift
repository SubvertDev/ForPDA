//
//  UIPost.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 18.10.2025.
//

import Models

public struct UIPost: Identifiable, Hashable, Equatable {
    public var id: Int { post.id }
    public let post: Post
    public let content: [Content]
    public let authorSignature: [Content]
    
    public init(
        post: Post,
        content: [Content],
        authorSignature: [Content]
    ) {
        self.post = post
        self.content = content
        self.authorSignature = authorSignature
    }
    
    public struct Content: Hashable {
        public let value: UITopicType
        
        public init(value: UITopicType) {
            self.value = value
        }
    }
}
