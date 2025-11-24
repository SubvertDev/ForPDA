//
//  SearchContent.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.25.
//

public enum SearchContent: Sendable {
    case post(HybridPost)
    case topic(TopicInfo)
    case article(ArticlePreview)
    
    public struct HybridPost: Sendable {
        public let topicId: Int
        public let topicName: String
        public let post: Post
        
        public init(topicId: Int, topicName: String, post: Post) {
            self.topicId = topicId
            self.topicName = topicName
            self.post = post
        }
    }
}

public extension SearchContent.HybridPost {
    static let mock = Self(
        topicId: 123,
        topicName: "ForPDA [iOS]",
        post: .mock()
    )
}
