//
//  UserService.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.10.2023.
//

import Foundation

protocol UserServicable {
    func user(id: String) async throws -> String
}

final class UserService: HTTPClient, UserServicable {
    
    func user(id: String) async throws -> String {
        return try await request(endpoint: UserEndpoint.user(id: id))
    }
}
