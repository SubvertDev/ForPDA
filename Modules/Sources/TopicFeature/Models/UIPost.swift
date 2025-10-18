//
//  UIPost.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 18.10.2025.
//

import Models

struct UIPost: Identifiable, Equatable {
    var id: Int { post.id }
    let post: Post
    let content: [Content]
    
    struct Content: Hashable {
        let value: TopicTypeUI
    }
}
