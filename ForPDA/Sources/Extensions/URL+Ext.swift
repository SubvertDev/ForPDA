//
//  URL+Ext.swift
//  ForPDA
//
//  Created by Subvert on 01.05.2023.
//

import Foundation

extension URL {
    
    func stripLastURLComponent() -> URL {
        var newUrl = self
        newUrl.deleteLastPathComponent()
        return newUrl
    }
}
