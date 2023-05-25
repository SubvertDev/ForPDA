//
//  URLComponents.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import Foundation

// MARK: - Components

extension URLComponents {
    
    // MARK: - News & Article
    
    static func news(page: Int) -> Self {
        Self(path: "/page/\(page)/")
    }
    
    static func article(path: [String]) -> Self {
        Self(path: path.joined(separator: "/"))
    }
    
    // MARK: - Login
    
    static var captcha: Self {
        Self(path: "/forum/index.php", queryItems: [URLQueryItem(name: "act", value: "auth")])
    }
    
    static var login: Self {
        Self(path: "/forum/index.php", queryItems: [URLQueryItem(name: "act", value: "auth")])
    }
    
    static func logout(key: String) -> Self {
        Self(path: "/forum/index.php",
             queryItems: [
                URLQueryItem(name: "act", value: "auth"),
                URLQueryItem(name: "action", value: "logout"),
                URLQueryItem(name: "k", value: key)
             ])
    }
    
    // MARK: - User
    
    static func user(id: String) -> Self {
        Self(path: "/forum/index.php", queryItems: [URLQueryItem(name: "showuser", value: id)])
    }
}

// MARK: - Init

extension URLComponents {
    init(scheme: String = "https",
         host: String = "4pda.to",
         path: String,
         queryItems: [URLQueryItem]? = nil) {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = queryItems
        self = components
    }
}
