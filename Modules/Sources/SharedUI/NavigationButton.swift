//
//  NavigationButton.swift
//
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import SwiftUI

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
