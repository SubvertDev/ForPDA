//
//  FavoritesNotificationSettings.swift
//  ForPDA
//
//  Created by Xialtal on 23.07.26.
//

import SwiftUI

enum FavoritesNotificationSettings: String, Sendable, Identifiable, CaseIterable {
    case all
    case important
    case no
    
    var id: String {
        return self.rawValue
    }
    
    var title: LocalizedStringKey {
        switch self {
        case .all:
            return "All"
        case .important:
            return "Only important"
        case .no:
            return "Do not"
        }
    }
}
