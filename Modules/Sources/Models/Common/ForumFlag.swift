//
//  ForumFlag.swift
//  ForPDA
//
//  Created by Xialtal on 13.01.26.
//

public struct ForumFlag: OptionSet, Sendable, Hashable, Codable {
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let pinned   = ForumFlag(rawValue: 1)
    public static let hidden   = ForumFlag(rawValue: 2)
    public static let closed   = ForumFlag(rawValue: 4)
    public static let favorite = ForumFlag(rawValue: 8)
    public static let marker   = ForumFlag(rawValue: 16)
    public static let updated  = ForumFlag(rawValue: 32)
    
    public static let canPost  = ForumFlag(rawValue: 64)
    public static let canEdit  = ForumFlag(rawValue: 128)
    public static let canDelete   = ForumFlag(rawValue: 256)
    public static let canModerate = ForumFlag(rawValue: 512)
    public static let canProtect  = ForumFlag(rawValue: 2048)
}
