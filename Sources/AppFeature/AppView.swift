//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import SwiftUI
import ComposableArchitecture
import NewsListFeature
import NewsFeature
import MenuFeature

public struct AppView: View {
    
    @Perception.Bindable public var store: StoreOf<AppFeature>
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                NewsListView(store: store.scope(state: \.newsList, action: \.newsList))
            } destination: { store in
                switch store.case {
                case .menu:
                    MenuViewSUI()
                    
                case let .news(store):
                    NewsView(store: store)
                }
            }
        }
    }
}
