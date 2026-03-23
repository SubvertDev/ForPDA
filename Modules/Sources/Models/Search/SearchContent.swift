//
//  SearchContent.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.25.
//

public enum SearchContent: Sendable, Equatable, Identifiable {
    case post(HybridPost)
    case topic(TopicInfo)
    case article(ArticlePreview)
    
    public var id: Int {
        switch self {
        case .post(let post):
            return post.id
        case .topic(let topic):
            return topic.id
        case .article(let article):
            return article.id
        }
    }
    
    public struct HybridPost: Sendable, Equatable, Identifiable {
        public let topicId: Int
        public let topicName: String
        public let post: Post
        
        public var id: Int { post.id }
        
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
