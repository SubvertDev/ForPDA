//
//  AuthService.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.10.2023.
//

import Foundation

protocol AuthServicable {
    func captcha() async throws -> String
    func login(multipart: [String: String]) async throws -> String
    func logout(key: String) async throws -> String
}

final class AuthService: HTTPClient, AuthServicable {
    
    func captcha() async throws -> String {
        return try await request(endpoint: AuthEndpoint.captcha)
    }
    
    func login(multipart: [String: String]) async throws -> String {
        return try await request(endpoint: AuthEndpoint.login(multipart: multipart))
    }
    
    func logout(key: String) async throws -> String {
        return try await request(endpoint: AuthEndpoint.logout(key: key))
    }
}
