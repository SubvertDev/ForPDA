//
//  TemplateSend.swift
//  ForPDA
//
//  Created by Xialtal on 6.06.25.
//

public enum TemplateSend: Sendable {
    case success(TemplateSendType)
    case error(TemplateSendError)
    
    public enum TemplateSendType: Sendable {
        case topic(id: Int)
        case post(PostSend)
    }
    
    public enum TemplateSendError: Sendable {
        case badParam
        case sentToPremod
        case fieldsError(String)
        case status(Int)
    }
    
    public var isError: Bool {
        return if case .error = self {
            true
        } else { false }
    }
}
