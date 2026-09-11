//
//  UserPunishmentCategory.swift
//  ForPDA
//
//  Created by Xialtal on 27.06.26.
//

public struct UserPunishmentCategory: Sendable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let supportsRestrictions: Bool
    public var templates: [UserPunishmentTemplate]
    
    public init(
        id: String,
        title: String,
        supportsRestrictions: Bool,
        templates: [UserPunishmentTemplate]
    ) {
        self.id = id
        self.title = title
        self.supportsRestrictions = supportsRestrictions
        self.templates = templates
    }
}

public extension UserPunishmentCategory {
    static let mockLight = UserPunishmentCategory(
        id: "light",
        title: "Warnings",
        supportsRestrictions: false,
        templates: [
            .default,
            .init(
                id: "offtop",
                flag: .deletePost,
                title: "Flood, offtop.",
                reason: "Violation of Clause 4.7 of the board rules.",
                message: "[b]See: ForPDA[/b]\n4.7. I'm too lazy, to translate this par."
            ),
            .init(
                id: "boardrules",
                flag: .init(rawValue: 1),
                title: "Read the board rules.",
                reason: "Read the board rules.",
                message: "[b]Read: ForPDA[/b]\n as Holly Bibble."
            ),
            .init(
                id: "overquote",
                flag: [],
                title: "Overquote.",
                reason: "Violation of Clause 4.19 of the board rules.",
                message: "[b]Sing: ForPDA[/b]\n as mom in your childhood."
            )
        ]
    )
    
    static let mockHigh = UserPunishmentCategory(
        id: "high",
        title: "Hight violation",
        supportsRestrictions: true,
        templates: [
            .default,
            .init(
                id: "insult",
                flag: [.deletePost, .addCurrentPremod, .addCurrentRO],
                title: "Obscene language.",
                reason: "Violation of Clause 4.28 of the board rules.",
                message: "[b]See: ForPDA[/b]\n4.28. I'm too lazy, to translate this par.",
                readOnlyHours: 0,
                premoderationHours: 72
            ),
            .init(
                id: "spam",
                flag: [.deletePost, .lastChance, .addCurrentPremod, .addCurrentRO],
                title: "Spammer.",
                reason: "Spammer.",
                message: "Spammer! Account banned.",
                readOnlyHours: 0,
                premoderationHours: 0
            ),
        ]
    )
}
