//
//  _GlassProminentButtonStyle.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 31.05.2026.
//

import SwiftUI

public extension View {
    func _glassProminentButtonStyle() -> some View {
        modifier(_GlassProminentButtonStyle())
    }
}

struct _GlassProminentButtonStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}
