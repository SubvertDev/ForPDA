//
//  Tab.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 13.11.2024.
//

import SwiftUI
import SFSafeSymbols

public enum AppTab: Int, CaseIterable, Sendable, Codable {
    case articles = 0
    case favorites
    case forum
    case profile
    case search
    
    // TODO: Title is in two places: AppFeature & AppSettings due to localization headache
    
    public var iconSymbol: SFSymbol {
        switch self {
        case .articles:
            return .docTextImage
        case .favorites:
            return .starBubble
        case .forum:
            return .bubbleLeftAndBubbleRight
        case .profile:
            return .personCropCircle
        case .search:
            return .magnifyingglass
        }
    }
}
