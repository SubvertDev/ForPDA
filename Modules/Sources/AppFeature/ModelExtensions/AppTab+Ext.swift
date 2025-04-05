//
//  AppTab+Ext.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 01.02.2025.
//

import SwiftUI
import Models

extension AppTab {
    public var title: LocalizedStringKey {
        switch self {
        case .articles:
            return "Articles"
        case .favorites:
            return "Favorites"
        case .forum:
            return "Forum"
        case .profile:
            return "Profile"
        }
    }
}
