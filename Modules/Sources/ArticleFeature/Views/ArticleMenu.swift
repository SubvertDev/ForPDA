//
//  CustomContextMenuModifier.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

public struct ArticleMenu: View {
    
    public let store: StoreOf<ArticleFeature>
    public let isDark: Bool
    
    public init(store: StoreOf<ArticleFeature>, isDark: Bool) {
        self.store = store
        self.isDark = isDark
    }
    
    public var body: some View {
        Menu {
            ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                store.send(.menuActionTapped(.copyLink))
            }
            ContextButton(text: LocalizedStringResource("Share Link", bundle: .module), symbol: .squareAndArrowUp) {
                store.send(.menuActionTapped(.shareLink))
            }
        } label: {
            Image(systemSymbol: .ellipsis)
                .font(.body)
                .foregroundStyle(foregroundStyle())
                .scaleEffect(isLiquidGlass ? 1 : 0.8)
                .background {
                    if !isLiquidGlass {
                        Circle()
                            .fill(Color.clear)
                            .background(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                }
                .animation(.default, value: isDark)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
    }
    
    @available(iOS, deprecated: 26.0)
    private func foregroundStyle() -> AnyShapeStyle {
        if isLiquidGlass {
            return AnyShapeStyle(.foreground)
        } else if isDark {
            return AnyShapeStyle(Color(.Labels.teritary))
        } else {
            return AnyShapeStyle(Color(.Labels.primaryInvariably))
        }
    }
}
