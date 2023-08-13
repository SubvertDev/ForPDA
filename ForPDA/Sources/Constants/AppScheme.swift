//
//  AppScheme.swift
//  ForPDA
//
//  Created by Subvert on 13.08.2023.
//

import Foundation

struct AppScheme {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
