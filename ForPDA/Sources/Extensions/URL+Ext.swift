//
//  URL+Ext.swift
//  ForPDA
//
//  Created by Subvert on 01.05.2023.
//

import Foundation

extension URL {
    
    static let fourpda = URL(string: "https://4pda.to/")!
    
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
