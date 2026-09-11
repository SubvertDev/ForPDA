//
//  UserPunishmentTemplate.swift
//  ForPDA
//
//  Created by Xialtal on 27.06.26.
//

public struct UserPunishmentTemplate: Sendable, Identifiable, Equatable {
    public let id: String
    public var flag: UserPunishmentTemplateFlag
    public let title: String
    public var reason: String
    public var message: String
    public var readOnlyHours: Int
    public var premoderationHours: Int
    
    public init(
        id: String,
        flag: UserPunishmentTemplateFlag,
        title: String,
        reason: String,
        message: String,
        readOnlyHours: Int = 0,
        premoderationHours: Int = 0
    ) {
        self.id = id
        self.flag = flag
        self.title = title
        self.reason = reason
        self.message = message
        self.readOnlyHours = readOnlyHours
        self.premoderationHours = premoderationHours
    }
}

public extension UserPunishmentTemplate {
    static let `default` = UserPunishmentTemplate(
        id: "Other",
        flag: .init(rawValue: 1409),
        title: "(Select template)",
        reason: "",
        message: "",
        readOnlyHours: 0,
        premoderationHours: 0
    )
}
