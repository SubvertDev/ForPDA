//
//  GlassEffectContainer.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 30.11.2025.
//

import SwiftUI

public struct _GlassEffectContainer<Content>: View where Content: View {
    
    let spacing: CGFloat?
    let content: () -> Content
    
    public init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing, content: content)
        } else {
            content()
        }
    }
}
