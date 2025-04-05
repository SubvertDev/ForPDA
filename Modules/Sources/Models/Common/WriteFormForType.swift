//
//  WriteFormForType.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

import Foundation

public enum WriteFormForType: Sendable, Equatable {
    case report(id: Int, type: ReportType)
    case topic(forumId: Int, content: [String])
    case post(topicId: Int, content: PostContentType)
    
    public enum PostContentType: Sendable, Equatable {
        case template([String])
        case simple(String, [Int])
    }
}
