//
//  FormType.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 20.07.2025.
//

import Models

public enum FormType: Sendable, Equatable {
    case post(type: PostType, topicId: Int, content: PostContentType)
    case report(id: Int, type: ReportType)
    case topic(forumId: Int, content: String)
    
    public enum PostType: Sendable, Equatable {
        case new
        case edit(postId: Int)
        
        @available(*, deprecated, message: "delete")
        func convert() -> WriteFormForType.PostType {
            switch self {
            case .new:
                return .new
            case .edit(let postId):
                return .edit(postId: postId)
            }
        }
    }
    
    public enum PostContentType: Sendable, Equatable {
        case simple(String, [Int])
        case template(String)
        
        @available(*, deprecated, message: "delete")
        func convert() -> WriteFormForType.PostContentType {
            switch self {
            case .simple(let string, let array):
                return .simple(string, array)
            case .template(let string):
                return .template(string)
            }
        }
    }
    
    public enum ReportType: Sendable, Equatable {
        case post
        case comment
        case reputation
        
        @available(*, deprecated, message: "delete")
        func convert() -> Models.ReportType {
            switch self {
            case .post:       return .post
            case .comment:    return .comment
            case .reputation: return .reputation
            }
        }
    }
    
    public var isTopic: Bool {
        if case .topic = self { true } else { false }
    }
}
