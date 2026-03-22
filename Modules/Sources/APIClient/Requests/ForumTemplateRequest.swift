//
//  ForumTemplateRequest.swift
//  ForPDA
//
//  Created by Xialtal on 15.03.25.
//

import PDAPI

public struct ForumTemplateRequest {
    public let id: Int
    public let action: TemplateAction
    
    public enum TemplateAction {
        case get
        case send([Any])
        case preview([Any])
    }
    
    public init(id: Int, action: TemplateAction) {
        self.id = id
        self.action = action
    }
}

extension ForumTemplateRequest.TemplateAction {
    var transferType: ForumCommand.TemplateAction {
        switch self {
        case .get: return .get
        case .preview: return .preview(Document())
        case .send: return .send(Document())
        }
    }
}
