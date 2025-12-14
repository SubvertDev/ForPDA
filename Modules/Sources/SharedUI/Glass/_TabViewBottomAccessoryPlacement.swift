//
//  _TabViewBottomAccessoryPlacement.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.12.2025.
//

import SwiftUI

public enum _TabViewBottomAccessoryPlacement: String {
    case inline
    case expanded
}

public extension EnvironmentValues {
    var _tabViewBottomAccessoryPlacement: _TabViewBottomAccessoryPlacement? {
        if #available(iOS 26, *) {
            switch tabViewBottomAccessoryPlacement {
            case .inline:     return .inline
            case .expanded:   return .expanded
            case .none:       return nil
            @unknown default: return nil
            }
        } else {
            return nil
        }
    }
}
