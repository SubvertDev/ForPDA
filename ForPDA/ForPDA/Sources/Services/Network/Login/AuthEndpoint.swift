//
//  AuthEndpoint.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.10.2023.
//

import Foundation

enum AuthEndpoint {
    case captcha
    case login(multipart: [String: String])
    case logout(key: String)
}

extension AuthEndpoint: Endpoint {
    var path: String {
        switch self {
        default:
            return "/forum/index.php"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .captcha:
            return .get
            
        case .login, .logout:
            return .post
        }
    }
    
    var header: [HTTPHeader]? {
        // Multipart header for logout will be handled in HTTPClient for now
        return nil
    }
    
    var body: [String: Any]? {
        return nil
    }
    
    var multipart: [String: String]? {
        switch self {
        case .captcha, .logout:
            return nil

        case .login(let multipart):
            return multipart
        }
    }
    
    var query: [String: String]? {
        switch self {
        case .captcha, .login:
            return ["act": "auth"]
            
        case .logout(let key):
            return [
                "act": "auth",
                "action": "logout",
                "k": key
            ]
        }
    }
}
