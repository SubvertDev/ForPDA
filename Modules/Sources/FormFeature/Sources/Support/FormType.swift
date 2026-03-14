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
    case topic(forumId: Int, content: [FormValue])
    
    public enum PostType: Sendable, Equatable {
        case new
        case edit(postId: Int)
    }
    
    public enum PostContentType: Sendable, Equatable {
        case simple(String, [FormAttachment])
        case template([FormValue])
    }
    
    public var isTopic: Bool {
        if case .topic = self { true } else { false }
    }
}
