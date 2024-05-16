//
//  User.swift
//  ForPDA
//
//  Created by Subvert on 22.05.2023.
//

import Foundation

struct User: Codable {
    let id: String
    let avatarUrl: String
    let nickname: String
    let title: String
    let role: String
    let registrationDate: String
    let warningsAmount: String
    let lastVisitDate: String
    let signature: String
}
