//
//  PostPreviewRequest.swift
//  ForPDA
//
//  Created by Xialtal on 15.03.25.
//

import PDAPI

public struct PostPreviewRequest: Sendable {
    public let id: Int
    public let post: PostRequest
    
    public init(
        id: Int,
        post: PostRequest
    ) {
        self.id = id
        self.post = post
    }
}
