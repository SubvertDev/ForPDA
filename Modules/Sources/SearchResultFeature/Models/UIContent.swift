//
//  UIContent.swift
//  ForPDA
//
//  Created by Xialtal on 29.11.25.
//

import Models
import SharedUI

public enum UIContent: Equatable, Hashable, Identifiable {
    case post(UIHybridPost)
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
    
    public struct UIHybridPost: Equatable, Hashable, Identifiable {
        public let topicId: Int
        public let topicName: String
        public let post: UIPost
        
        public var id: Int { post.id }
        
        public init(
            topicId: Int,
            topicName: String,
            post: UIPost
        ) {
            self.topicId = topicId
            self.topicName = topicName
            self.post = post
        }
    }
}
