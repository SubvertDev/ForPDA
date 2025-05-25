//
//  PostSend.swift
//  ForPDA
//
//  Created by Xialtal on 18.03.25.
//

public struct PostSend: Sendable {
    public let id: Int
    public let topicId: Int
    public let offset: Int
    
    public init(
        id: Int,
        topicId: Int,
        offset: Int
    ) {
        self.id = id
        self.topicId = topicId
        self.offset = offset
    }
}
