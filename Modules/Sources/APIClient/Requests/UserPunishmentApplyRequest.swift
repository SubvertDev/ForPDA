//
//  UserPunishmentApplyRequest.swift
//  ForPDA
//
//  Created by Xialtal on 11.09.26.
//

import Models

public struct UserPunishmentApplyRequest: Sendable {
    public let userId: Int
    public let subjectId: Int
    public let categoryId: String
    public let template: UserPunishmentTemplate
    
    public init(userId: Int, subjectId: Int, categoryId: String, template: UserPunishmentTemplate) {
        self.userId = userId
        self.subjectId = subjectId
        self.categoryId = categoryId
        self.template = template
    }
}
