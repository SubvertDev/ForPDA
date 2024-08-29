//
//  AuthEvent.swift
//
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import Foundation

public enum AuthEvent: Event {
    case loginTapped
    case wrongPassword
    case wrongCaptcha
    case loginSuccess(Int)
    
    public var name: String {
        return "Authorization " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .loginSuccess(userId):
            return ["userId": String(userId)]
        default:
            return nil
        }
    }
}
