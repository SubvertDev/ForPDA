//
//  ContextButton.swift
//
//
//  Created by Ilia Lubianoi on 17.05.2024.
//

import SwiftUI
import SFSafeSymbols

// MARK: - Context Button

public struct ContextButton: View {
    
    public let text: LocalizedStringResource
    public let symbol: SFSymbol
    public let role: ButtonRole?
    public let action: (() -> Void)
    
    public init(
        text: LocalizedStringResource,
        symbol: SFSymbol,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.symbol = symbol
        self.role = role
        self.action = action
    }
    
    public var body: some View {
        Button(role: role) {
            action()
        } label: {
            HStack {
                Text(text)
                Image(systemSymbol: symbol)
            }
        }
    }
}
