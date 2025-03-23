//
//  WriteFormForType.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

import Foundation

public enum WriteFormForType: Sendable, Equatable {
    case topic(forumId: Int, content: [String])
    case post(topicId: Int, content: PostContentType)
    case report(id: Int, content: String, type: ReportType)
    
    public enum PostContentType: Sendable, Equatable {
        case template([String])
        case simple(String, [Int])
    }
    
    public enum ReportType: Sendable, Equatable {
        case post
        case comment
        case reputation
    }
}
