//
//  ModernCircularLoader.swift
//
//
//  Created by Ilia Lubianoi on 19.05.2024.
//

import SwiftUI

public struct ModernCircularLoader: View {
    
    @Environment(\.tintColor) private var tintColor
    @State private var trimEnd = 0.75
    @State private var animate = false
    private let lineWidth: Double
    
    public init(
        lineWidth: Double = 3
    ) {
        self.lineWidth = lineWidth
    }
    
    public var body: some View {
        Circle()
            .trim(from: 0.0, to: trimEnd)
            .stroke(.foreground, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin:.round))
            .animation(
                Animation.easeIn(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: trimEnd
            )
            .rotationEffect(Angle(degrees: animate ? 270 + 360 : 270))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: animate
            )
            .foregroundStyle(tintColor)
            .onAppear {
                Task { @MainActor in
                    animate = true
                    trimEnd = 0
                }
            }
    }
}

#Preview {
    ModernCircularLoader()
        .frame(width: 24, height: 24)
}
