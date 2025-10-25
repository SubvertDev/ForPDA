//
//  DisplayMode.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 25.10.2025.
//

import SwiftUI

public enum ToolbarDisplayMode {
    
    case inline
    case inlineLarge
    case large
    case automatic
    
    @available(iOS 17, *)
    func toToolbarTitleDisplayMode() -> ToolbarTitleDisplayMode {
        switch self {
        case .inline:      return .inline
        case .inlineLarge: return .inlineLarge
        case .large:       return .large
        case .automatic:   return .automatic
        }
    }
    
    func toTitleDisplayMode() -> NavigationBarItem.TitleDisplayMode {
        switch self {
        case .inline:      return .inline
        case .inlineLarge: return .large // .inlineLarge is mapped to .large
        case .large:       return .large
        case .automatic:   return .automatic
        }
    }
}

public extension View {
    func _toolbarTitleDisplayMode(_ mode: ToolbarDisplayMode) -> some View {
        if #available(iOS 17, *) {
            return toolbarTitleDisplayMode(mode.toToolbarTitleDisplayMode())
        } else {
            return navigationBarTitleDisplayMode(mode.toTitleDisplayMode())
        }
    }
}
