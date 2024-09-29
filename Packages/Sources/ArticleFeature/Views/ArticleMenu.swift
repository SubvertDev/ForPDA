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
            ContextButton(text: "Copy Link", symbol: .docOnDoc, bundle: .module) {
                store.send(.menuActionTapped(.copyLink))
            }
            ContextButton(text: "Share Link", symbol: .squareAndArrowUp, bundle: .module) {
                store.send(.menuActionTapped(.shareLink))
            }
            ContextButton(text: "Problems with article?", symbol: .questionmarkCircle, bundle: .module) {
                store.send(.menuActionTapped(.report))
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .background(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                Image(systemSymbol: .ellipsis)
                    .font(.body)
                    .foregroundStyle(isDark ? Color.Labels.teritary : Color.Labels.primaryInvariably)
                    .scaleEffect(0.8) // TODO: ?
                    .animation(.default, value: isDark)
            }
        }
    }
}
