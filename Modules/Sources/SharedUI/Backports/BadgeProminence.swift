//
//  BadgeProminence.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 21.02.2026.
//

import SwiftUI

public enum _BadgeProminence {
    case increased
    case standard
    case decreased
    
    @available(iOS 17, *)
    public var asBadgeProminence: BadgeProminence {
        switch self {
        case .increased: return .increased
        case .standard:  return .standard
        case .decreased: return .decreased
        }
    }
}

public extension View {
    @ViewBuilder
    func _badgeProminence(_ prominence: _BadgeProminence) -> some View {
        if #available(iOS 17, *) {
            badgeProminence(prominence.asBadgeProminence)
        } else {
            self
        }
    }
}
