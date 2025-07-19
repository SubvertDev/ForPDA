//
//  ReportRequest.swift
//  ForPDA
//
//  Created by Xialtal on 26.03.25.
//

import PDAPI
import Models

public struct ReportRequest: Sendable {
    public let id: Int
    public let type: ReportType
    public let message: String
    
    public var transferType: CommonCommand.ReportCode {
        switch type {
        case .post: return .post
        case .comment: return .comment
        case .reputation: return .reputation
        }
    }
    
    public init(
        id: Int,
        type: ReportType,
        message: String
    ) {
        self.id = id
        self.type = type
        self.message = message
    }
}
