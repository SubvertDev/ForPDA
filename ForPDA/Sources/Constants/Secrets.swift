//
//  Secrets.swift
//  ForPDA
//
//  Created by Subvert on 13.08.2023.
//
//  swiftlint:disable identifier_name

import Foundation

struct Secrets {
    
    enum Keys: String {
        case SENTRY_DSN
        case MIXPANEL_TOKEN
    }
    
    static func `for`(key: Keys) -> String {
        if let dictionary = Bundle.main.object(forInfoDictionaryKey: "SECRET_KEYS") as? [String: String] {
            return dictionary[key.rawValue] ?? ""
        } else {
            return ""
        }
    }
}
