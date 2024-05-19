//
//  URL+Ext.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public extension URL {
    
    static let fourpda = URL(string: "https://4pda.to/")!
    static let github = URL(string: "https://github.com/SubvertDev/ForPDA/")!
    static let defaultAvatar = URL(string: "https://4pda.to/s/PXtijiHlTQLQuS20Pw2juZgaB7jch8eE.jpg")!
    
    static func fourpda(page: Int) -> URL {
        return URL(string: "https://4pda.to/page/\(page)/")!
    }
    
    static func githubRelease() -> URL {
        if let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return URL(string: "https://github.com/SubvertDev/ForPDA/releases/tag/v\(marketingVersion)/")!
        } else {
            return URL(string: "https://github.com/SubvertDev/ForPDA/")!
        }
    }
    
    func stripLastURLComponent() -> URL {
        var newUrl = self
        newUrl.deleteLastPathComponent()
        return newUrl
    }
}
