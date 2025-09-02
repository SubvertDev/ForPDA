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
        }
    }
    
    public var title: LocalizedStringResource {
        switch self {
        case .articles:
            return LocalizedStringResource("Articles", bundle: .module)
        case .favorites:
            return LocalizedStringResource("Favorites", bundle: .module)
        case .forum:
            return LocalizedStringResource("Forum", bundle: .module)
        case .profile:
            return LocalizedStringResource("Profile", bundle: .module)
        }
    }
}
