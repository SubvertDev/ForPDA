//
//  NotificationsSettings.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//


public struct NotificationsSettings: Sendable, Codable, Hashable {
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
}

extension NotificationsSettings {
    static let `default` = NotificationsSettings(
        isQmsEnabled: true,
        isForumEnabled: true,
        isTopicsEnabled: true,
        isForumMentionsEnabled: true,
        isSiteMentionsEnabled: true
    )
}
