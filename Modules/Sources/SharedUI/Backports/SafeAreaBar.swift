//
//  SafeAreaBar.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 26.10.2025.
//

import SwiftUI

public extension View {
    
    // NOTE:
    // safeAreaBar blocks taps so you can't scroll anything behind it
    
    @available(iOS, deprecated: 26, message: "Use native safeAreaBar instead")
    func _safeAreaBar<Content: View>(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 26, *) {
            return safeAreaBar(edge: edge, alignment: alignment, spacing: spacing, content: content)
        } else {
            return safeAreaInset(edge: edge, alignment: alignment, spacing: spacing, content: content)
        }
    }
}
