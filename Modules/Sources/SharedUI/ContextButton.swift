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
    public let action: (() -> Void)
    
    public init(
        text: LocalizedStringResource,
        symbol: SFSymbol,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.symbol = symbol
        self.action = action
    }
    
    public var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(text)
                Image(systemSymbol: symbol)
            }
        }
    }
}
