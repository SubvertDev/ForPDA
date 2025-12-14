//
//  UnavailableView.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 20.09.2025.
//

import SwiftUI
import SFSafeSymbols

public struct UnavailableView: View {
    
    // MARK: - Properties
    
    @Environment(\.tintColor) private var tintColor
    
    private let symbol: SFSymbol
    private let title: LocalizedStringKey
    private let description: LocalizedStringKey
    private let actionTitle: LocalizedStringKey?
    private let action: (() -> Void)?
    private let bundle: Bundle
    
    // MARK: - Init
    
    public init(
        symbol: SFSymbol,
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil,
        bundle: Bundle
    ) {
        self.symbol = symbol
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
        self.bundle = bundle
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            Image(systemSymbol: symbol)
                .font(.title)
                .foregroundStyle(tintColor)
                .padding(.bottom, 8)
            
            Text(title, bundle: bundle)
                .font(.title3)
                .fontWeight(.semibold)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text(description, bundle: bundle)
                .font(.footnote)
                .foregroundStyle(Color(.Labels.teritary))
            
            if let actionTitle {
                Button {
                    action?()
                } label: {
                    Text(actionTitle, bundle: bundle)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.bordered)
                .padding(.top, 16)
                .tint(tintColor)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UnavailableView(
        symbol: .exclamationmarkTriangleFill,
        title: "Couldn't load",
        description: "Try again later",
        actionTitle: "Try again",
        action: {},
        bundle: .main
    )
    .environment(\.tintColor, Color(.Theme.primary))
}
