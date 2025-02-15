//
//  AuthResponse.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import Foundation

public enum AuthResponse: Sendable {
    case success(userId: Int, token: String) // 0
    case wrongPassword // 3
    case wrongCaptcha(url: URL) // 4
    case unknown(Int)
}
