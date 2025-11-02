//
//  InScrollContentDetector.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 31.10.2025.
//

import SwiftUI

private struct ScrollMetrics: Equatable {
    var offset: CGPoint
    var contentHeight: CGFloat
}

public extension View {
    
    func _inScrollContentDetector(state: Binding<Bool>) -> some View {
        if #available(iOS 18, *) {
            return modifier(InScrollContentDetector(state: state))
        } else {
            return self
        }
    }
}

@available(iOS 18, *)
public struct InScrollContentDetector: ViewModifier {
    
    @State private var scrollHeight: CGFloat = 0
    @State private var lastManualChange: Date = .distantPast
    private let changeDelay: TimeInterval = 1
    
    @Binding private var state: Bool
    
    public init(state: Binding<Bool>) {
        self._state = state
    }
    
    public func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollMetrics.self) { geometry in
                ScrollMetrics(
                    offset: geometry.contentOffset,
                    contentHeight: geometry.contentSize.height
                )
            } action: { old, new in
                // TODO: <OnScrollGeometryChange Modifier> tried to update multiple times per frame.
                guard old != new else { return }
                guard Date().timeIntervalSince(lastManualChange) > changeDelay else { return }
                let isPastFirstHalf = new.offset.y > (scrollHeight / 2)
                let isBeforeLastHalf = new.offset.y < (new.contentHeight - scrollHeight * 1.5)
                state = isPastFirstHalf && isBeforeLastHalf
            }
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                guard newSize.height != scrollHeight else { return }
                scrollHeight = newSize.height
            }
            .onChange(of: state) { _ in
                lastManualChange = .now
            }
    }
}
