//
//  Effects.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 13.09.2024.
//

import SwiftUI

// MARK: - Replace DownUp ByLayer

public struct ReplaceDownUpByLayerEffect: ViewModifier {
    
    public var value: Bool
    
    public init(value: Bool) {
        self.value = value
    }
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.symbolEffect(.replace.downUp.byLayer))
        } else {
            content
        }
    }
}

// Extension for easier use
public extension View {
    func replaceDownUpByLayerEffect(value: Bool) -> some View {
        self.modifier(ReplaceDownUpByLayerEffect(value: value))
    }
}

// MARK: - Bounce Up ByLayer

public struct BounceUpByLayerEffect: ViewModifier {
    
    public var value: Bool
    
    public init(value: Bool) {
        self.value = value
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .symbolEffect(.bounce.up.byLayer, value: value)
        } else {
            content
        }
    }
}

public extension View {
    func bounceUpByLayerEffect(value: Bool) -> some View {
        self.modifier(BounceUpByLayerEffect(value: value))
    }
}
