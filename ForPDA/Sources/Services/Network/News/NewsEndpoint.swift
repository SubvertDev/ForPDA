//
//  AuthEndpoint.swift
//  ForPDA
//
//  Created by Subvert on 19.10.2023.
//

import Foundation

enum NewsEndpoint {
    case news(page: Int)
    case article(path: [String])
    case comments(path: [String])
}

extension NewsEndpoint: Endpoint {
    var forceFLS: Bool {
        return false
    }
    
    var path: String {
        switch self {
        case .news(page: let page):
            return page == 1 ? "" : "/page/\(page)/"
            
        case .article(path: let path):
            return path.joined(separator: "/").removing(prefix: "/")
            
        case .comments(path: let path):
            return path.joined(separator: "/").removing(prefix: "/")
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var header: [HTTPHeader]? {
        return nil
    }
    
    var body: [String: Any]? {
        return nil
    }
    
    var multipart: [String: String]? {
        return nil
    }
    
    var query: [String: String]? {
        return nil
    }
}
