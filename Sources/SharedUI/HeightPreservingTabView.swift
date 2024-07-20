//
//  HeightPreservingTabView.swift
//
//
//  Created by Ilia Lubianoi on 06.07.2024.
//

import SwiftUI

public struct HeightPreservingTabView<Content: View>: View {
    @ViewBuilder public var content: () -> Content
    
    // `minHeight` needs to start as something non-zero or we won't measure the interior content height
    @State private var minHeight: CGFloat = 1
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        TabView {
            content()
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: TabViewMinHeightPreference.self,
                            value: geometry.frame(in: .local).height
                        )
                    }
                }
        }
        .frame(minHeight: minHeight)
        .onPreferenceChange(TabViewMinHeightPreference.self) { minHeight in
            self.minHeight = minHeight
        }
    }
}

private struct TabViewMinHeightPreference: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // It took me so long to debug this line
        value = max(value, nextValue())
    }
}
