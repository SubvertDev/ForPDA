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
    
    public let text: LocalizedStringKey
    public let symbol: SFSymbol
    public let bundle: Bundle
    public let action: (() -> Void)
    
    public init(
        text: LocalizedStringKey,
        symbol: SFSymbol,
        bundle: Bundle,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.symbol = symbol
        self.bundle = bundle
        self.action = action
    }
    
    public var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(text, bundle: bundle)
                Image(systemSymbol: symbol)
            }
        }
    }
}
