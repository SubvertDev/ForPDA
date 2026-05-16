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
    
    // MARK: - Properties
    
    @Environment(\.tintColor) private var tintColor
    
    public let text: LocalizedStringResource
    public let symbol: SFSymbol
    public let role: ButtonRole?
    public let action: (() -> Void)
    
    // MARK: - Init
    
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
    
    // MARK: - Body
    
    public var body: some View {
        Button(role: role) {
            action()
        } label: {
            Label {
                Text(text)
            } icon: {
                Image(systemSymbol: symbol)
                    .if(role == .destructive) { view in
                        view.tint(.red)
                    }
            }
        }
    }
}
