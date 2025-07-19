//
//  Links.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

// TODO: Duplicate on github?

public enum Links {
    
    public static let _4pda = URL(string: "https://4pda.to/")!
    public static let _4pdaAuthor = URL(string: "https://4pda.to/forum/index.php?showuser=3640948")!
    public static let boosty = URL(string: "https://boosty.to/forpda")!
    public static let appDiscussion = URL(string: "https://4pda.to/forum/index.php?showtopic=1104159")!
    public static let telegramChangelog = URL(string: "https://t.me/forpda_ios")!
    public static let telegramChat = URL(string: "https://t.me/forpda_ios_chat")!
    public static let github = URL(string: "https://github.com/SubvertDev/ForPDA/")!
    public static let githubReleases = URL(string: "https://github.com/SubvertDev/ForPDA/releases/")!
    public static let defaultAvatar = URL(string: "https://4pda.to/s/PXtijiHlTQLQuS20Pw2juZgaB7jch8eE.jpg")!
    
    // TODO: Check if needed
    
//    static func githubRelease() -> URL {
//        if let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
//            return URL(string: "https://github.com/SubvertDev/ForPDA/releases/tag/v\(marketingVersion)/")!
//        } else {
//            return URL(string: "https://github.com/SubvertDev/ForPDA/")!
//        }
//    }
}
