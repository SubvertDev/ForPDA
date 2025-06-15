//
//  PostSend.swift
//  ForPDA
//
//  Created by Xialtal on 18.03.25.
//

public enum PostSendResponse: Sendable {
    case success(PostSend)
    case failure(PostSendError)
}

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

public enum PostSendError: Int, Sendable {
    // case success = 0
    case premoderation = 4
    case tooLong = 5
    case alreadySent = 6
    case attach = 7
    case unknown
}
