//
//  UserEndpoint.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.10.2023.
//

import Foundation

enum UserEndpoint {
    case user(id: String)
}

extension UserEndpoint: Endpoint {
    var path: String {
        switch self {
        case .user:
            return "/forum/index.php"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var header: [HTTPHeader]? {
        return nil
    }
    
    var body: [String : Any]? {
        return nil
    }
    
    var multipart: [String: String]? {
        return nil
    }
    
    var query: [String : String]? {
        switch self {
        case .user(let id):
            return ["showuser": id]
        }
    }
}
