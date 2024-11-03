//
//  ParallaxHeader.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.09.2024.
//

import SwiftUI

struct ParallaxHeader<Content: View, Space: Hashable>: View {
    let content: () -> Content
    let coordinateSpace: Space
    let defaultHeight: CGFloat
    let safeAreaTopHeight: CGFloat
    
    init(
        coordinateSpace: Space,
        defaultHeight: CGFloat,
        safeAreaTopHeight: CGFloat,
        @ViewBuilder _ content: @escaping () -> Content
    ) {
        self.content = content
        self.coordinateSpace = coordinateSpace
        self.defaultHeight = defaultHeight
        self.safeAreaTopHeight = safeAreaTopHeight
    }
    
    var body: some View {
        GeometryReader { proxy in
            let offset = offset(for: proxy)
            let heightModifier = heightModifier(for: proxy)
            content()
                .edgesIgnoringSafeArea(.horizontal)
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height + heightModifier
                )
                .offset(y: offset)
        }
        .frame(height: defaultHeight)
    }
    
    private func offset(for proxy: GeometryProxy) -> CGFloat {
        let frame = proxy.frame(in: .named(coordinateSpace))
        if frame.minY + safeAreaTopHeight < 0 { return 0 }
        return -frame.minY - safeAreaTopHeight
    }
    
    private func heightModifier(for proxy: GeometryProxy) -> CGFloat {
        let frame = proxy.frame(in: .named(coordinateSpace))
        return max(0, frame.minY + safeAreaTopHeight)
    }
}
