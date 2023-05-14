//
//  URLComponents.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import Foundation

// MARK: - Components

extension URLComponents {
    static func news(page: Int) -> Self {
        Self(path: "/page/\(page)/")
    }
    
    static func article(path: String) -> Self {
        Self(path: "\(path)")
    }
    
    static var captcha: Self {
        Self(path: "/forum/index.php", queryItems: [URLQueryItem(name: "act", value: "auth")])
    }
}

// MARK: - Init

extension URLComponents {
    init(scheme: String = "https",
         host: String = "www.4pda.to",
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
