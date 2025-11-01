//
//  DebugBorder.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.10.2025.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func debugBorder() -> some View {
        #if DEBUG
            self.border(Color.random)
        #else
            self
        #endif
    }
}

private extension Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
