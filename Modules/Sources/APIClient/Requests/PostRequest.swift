//
//  PostRequest.swift
//  ForPDA
//
//  Created by Xialtal on 18.03.25.
//

public struct PostRequest: Sendable {
    public let topicId: Int
    public let content: String
    public let flag: Int
    public let attachments: [Int]
    
    public init(
        topicId: Int,
        content: String,
        flag: Int,
        attachments: [Int]
    ) {
        self.topicId = topicId
        self.content = content
        self.flag = flag
        self.attachments = attachments
    }
}
