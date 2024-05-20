//
//  Login.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public enum LoginEvent: Event {
    case closed
    case authSuccess(_ username: String)
    case authFailure(_ failureMessage: String)
    
    public var name: String {
        return "Login " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case .authSuccess(let username):
            return ["username": username]
        case .authFailure(let failureMessage):
            return ["failure_message": failureMessage]
        default:
            return nil
        }
    }
}
