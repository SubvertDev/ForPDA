//
//  StackTabView.swift
//  AppFeature
//
//  Created by Ilia Lubianoi on 30.03.2025.
//

import SwiftUI
import ComposableArchitecture

public struct StackTabView: View {
    
    @Perception.Bindable public var store: StoreOf<StackTab>
    
    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(\.path, action: \.path)) {
                Path.view(store.scope(\.root, action: \.root))
            } destination: { store in
                WithPerceptionTracking {
                    Path.view(store)
                }
            }
            .toolbar(store.showTabBar ? .visible : .hidden, for: .tabBar)
            .animation(.default, value: store.root) // Animation for root change
            .onAppear { store.send(.onAppear) }
        }
    }
}
