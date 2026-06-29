//
//  UserPunishmentTemplateFlag.swift
//  ForPDA
//
//  Created by Xialtal on 27.06.26.
//

public struct UserPunishmentTemplateFlag: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let deletePost       = UserPunishmentTemplateFlag(rawValue: 1 << 2)
    public static let alwaysPremod     = UserPunishmentTemplateFlag(rawValue: 1 << 3)
    public static let lastChance       = UserPunishmentTemplateFlag(rawValue: 1 << 4)
    public static let fullBan          = UserPunishmentTemplateFlag(rawValue: 1 << 5)
    public static let addCurrentPremod = UserPunishmentTemplateFlag(rawValue: 1 << 7)
    public static let addCurrentRO     = UserPunishmentTemplateFlag(rawValue: 1 << 8)
    public static let customText       = UserPunishmentTemplateFlag(rawValue: 1 << 10)
}
