//
//  URLRequest.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import Foundation

// MARK: - Requests

extension URLRequest {
    static func news(page: Int) -> Self {
        Self(components: .news(page: page))
            .add(httpMethod: .get)
    }
    
    static var captcha: Self {
        Self(components: .captcha)
            .add(httpMethod: .get)
    }
}

// MARK: - Init

extension URLRequest {
    init(components: URLComponents) {
        guard let url = components.url else {
            preconditionFailure("Unable to get URL from URLComponents: \(components)")
        }

        self = Self(url: url)
    }

    private func map(_ transform: (inout Self) -> Void) -> Self {
        var request = self
        transform(&request)
        return request
    }

    func add(httpMethod: HTTPMethod) -> Self {
        map { $0.httpMethod = httpMethod.rawValue }
    }

    func add<Body: Encodable>(body: Body) -> Self {
        map {
            do {
                $0.httpBody = try JSONEncoder().encode(body)
            } catch {
                preconditionFailure("Failed to encode request Body: \(body) due to Error: \(error)")
            }
        }
    }

    func add(data: Data?) -> Self {
        map {
            $0.httpBody = data
        }
    }

    func add(headers: [String: String]) -> Self {
        map {
            var allHTTPHeaderFields = $0.allHTTPHeaderFields ?? [:]
            
            headers.forEach { (key, value) in allHTTPHeaderFields[key] = value }
            $0.allHTTPHeaderFields = allHTTPHeaderFields
        }
    }
    
    func withNewAuthorizationToken(_ accessToken: String) -> Self {
        return self.add(headers: ["Authorization": "Bearer \(accessToken)"])
    }
}
