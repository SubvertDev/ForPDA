//
//  AuthService.swift
//  ForPDA
//
//  Created by Subvert on 19.10.2023.
//

import Foundation

protocol NewsServicable {
    func news(page: Int) async throws -> String
    func article(path: [String]) async throws -> String
}

final class NewsService: HTTPClient, NewsServicable {
    
    func news(page: Int) async throws -> String {
        return try await request(endpoint: NewsEndpoint.news(page: page))
    }
    
    func article(path: [String]) async throws -> String {
        return try await request(endpoint: NewsEndpoint.article(path: path))
    }
}
