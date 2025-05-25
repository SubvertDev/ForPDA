//
//  PostEditRequest.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 25.05.2025.
//

public struct PostEditRequest: Sendable {
    public let postId: Int
    public let reason: String
    public let data: PostRequest
    
    public init(
        postId: Int,
        reason: String,
        data: PostRequest
    ) {
        self.postId = postId
        self.reason = reason
        self.data = data
    }
}
