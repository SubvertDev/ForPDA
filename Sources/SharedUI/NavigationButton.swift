//
//  NavigationButton.swift
//
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import SwiftUI

public extension PrimitiveButtonStyle where Self == NavigationButtonStyle<PlainButtonStyle> {
    static var navigation: NavigationButtonStyle<PlainButtonStyle> {
        NavigationButtonStyle(style: .plain)
    }
}

public extension PrimitiveButtonStyle {
    var navigation: NavigationButtonStyle<Self> {
        NavigationButtonStyle(style: self)
    }
}

struct _X: Hashable {}

public struct NavigationButtonStyle<S: PrimitiveButtonStyle>: PrimitiveButtonStyle {
    
    public let style: S
    
    public func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            NavigationLink(value: _X()) {
                configuration.label.onTapGesture {
                    configuration.trigger()
                }
            }
            .buttonStyle(.plain)
        }
        .buttonStyle(style)
    }
}

public struct ListButtonStyle: ButtonStyle {
    
    public static let accent = Color.gray.opacity(0.5)
    
    public init() {}
    
    public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        MyButton(configuration: configuration)
            .background(configuration.isPressed ? Self.accent : .clear)
    }

    struct MyButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label.opacity(isEnabled ? 1 : 0.5)
        }
    }
}
