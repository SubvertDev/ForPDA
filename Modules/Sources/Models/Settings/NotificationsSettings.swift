//
//  NotificationsSettings.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

public struct NotificationsSettings: OptionSet, Sendable, Codable, Hashable {
    public var rawValue: Int
    
    public var isAnyEnabled: Bool {
        return !self.isEmpty
    }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let qms              = NotificationsSettings(rawValue: 1 << 0)   // 1
    public static let qmsSystemEvents  = NotificationsSettings(rawValue: 1 << 1)   // 2
    public static let favorites        = NotificationsSettings(rawValue: 1 << 2)   // 4
    public static let favoritesImportant = NotificationsSettings(rawValue: 1 << 3) // 8
    public static let mentions         = NotificationsSettings(rawValue: 1 << 4)   // 16
}

extension NotificationsSettings {
    static let `default` = NotificationsSettings([
        .qms,
        .qmsSystemEvents,
        .favorites,
        .mentions
    ])
}

public struct NotificationsSettingsOld: Sendable, Codable, Hashable {
    public var isQmsEnabled: Bool
    public var isForumEnabled: Bool
    public var isTopicsEnabled: Bool
    public var isForumMentionsEnabled: Bool
    public var isSiteMentionsEnabled: Bool
    
    public var isAnyEnabled: Bool {
        return isQmsEnabled || isForumEnabled || isTopicsEnabled || isForumMentionsEnabled || isSiteMentionsEnabled
    }
    
    public init(
        isQmsEnabled: Bool,
        isForumEnabled: Bool,
        isTopicsEnabled: Bool,
        isForumMentionsEnabled: Bool,
        isSiteMentionsEnabled: Bool
    ) {
        self.isQmsEnabled = isQmsEnabled
        self.isForumEnabled = isForumEnabled
        self.isTopicsEnabled = isTopicsEnabled
        self.isForumMentionsEnabled = isForumMentionsEnabled
        self.isSiteMentionsEnabled = isSiteMentionsEnabled
    }
    
    public func asDictionary() -> [String: Any] {
        return [
            "isQmsEnabled": isQmsEnabled,
            "isForumEnabled": isForumEnabled,
            "isTopicsEnabled": isTopicsEnabled,
            "isForumMentionsEnabled": isForumMentionsEnabled,
            "isSiteMentionsEnabled": isSiteMentionsEnabled,
        ]
    }
}

extension NotificationsSettingsOld {
    static let `default` = NotificationsSettingsOld(
        isQmsEnabled: true,
        isForumEnabled: true,
        isTopicsEnabled: true,
        isForumMentionsEnabled: true,
        isSiteMentionsEnabled: true
    )
}
