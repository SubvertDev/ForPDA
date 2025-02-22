//
//  FavoriteInfo.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

public struct FavoriteInfo: Codable, Hashable, Sendable {
    public let flag: Int
    public let topic: TopicInfo
    public let isForum: Bool
    
    public enum Notify {
        case always
        case once
        case doNot
    }
    
    public var notify: Notify {
        return switch (flag & 3) {
            case 2: .doNot
            case 1: .once
            default: .always
        }
    }
    
    public var isImportant: Bool {
        return (topic.flag & 1) > 0
    }
    
    public var isNotifyHatUpdate: Bool {
        return (flag & 4) > 0
    }
    
    public init(
        flag: Int,
        topic: TopicInfo,
        isForum: Bool
    ) {
        self.flag = flag
        self.topic = topic
        self.isForum = isForum
    }
}

public extension FavoriteInfo {
    static let mock = FavoriteInfo(
        flag: 0,
        topic: .mockToday,
        isForum: false
    )
    
    static let mockUnread = FavoriteInfo(
        flag: 0,
        topic: .mockTodayUnread,
        isForum: false
    )
}
