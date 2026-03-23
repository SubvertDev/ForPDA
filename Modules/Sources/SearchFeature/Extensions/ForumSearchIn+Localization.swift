//
//  ForumSearchIn+Localization.swift
//  ForPDA
//
//  Created by Xialtal on 25.11.25.
//

import SwiftUI
import Models

extension ForumSearchIn {
    var title: LocalizedStringKey {
        return switch self {
        case .all:    "Everywhere"
        case .posts:  "Only in posts"
        case .titles: "Only in titles"
        }
    }
}
