//
//  Favorite.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

public struct Favorite: Codable, Hashable, Sendable {
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
            case 0: .doNot
            case 2: .once
            default: .always
        }
    }
    
    public var isImportant: Bool {
        return (topic.flag & 1) > 0
    }
    
    public var isNotifyHatUpdate: Bool {
        return ((flag & 3) & 4) > 0
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

public extension Favorite {
    static let mock = Favorite(
        flag: 73,
        topic: .mockToday,
        isForum: false
    )
}
