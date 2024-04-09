//
//  User.swift
//  ForPDA
//
//  Created by Subvert on 22.05.2023.
//

import Foundation

public struct User: Codable {
    public let id: String
    public let avatarUrl: String
    public let nickname: String
    public let title: String
    public let role: String
    public let registrationDate: String
    public let warningsAmount: String
    public let lastVisitDate: String
    public let signature: String
    
    public init(
        id: String,
        avatarUrl: String,
        nickname: String,
        title: String,
        role: String,
        registrationDate: String, 
        warningsAmount: String,
        lastVisitDate: String,
        signature: String
    ) {
        self.id = id
        self.avatarUrl = avatarUrl
        self.nickname = nickname
        self.title = title
        self.role = role
        self.registrationDate = registrationDate
        self.warningsAmount = warningsAmount
        self.lastVisitDate = lastVisitDate
        self.signature = signature
    }
}
