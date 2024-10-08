//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import SwiftUI
import ComposableArchitecture
import ArticlesListFeature
import ArticleFeature
import MenuFeature
import AuthFeature
import ProfileFeature
import SettingsFeature
import AlertToast

public struct AppView: View {
    
    @Perception.Bindable public var store: StoreOf<AppFeature>
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                ArticlesListScreen(store: store.scope(state: \.articlesList, action: \.articlesList))
            } destination: { store in
                switch store.case {
                case let .article(store):
                    ArticleScreen(store: store)
                    
                case let .menu(store):
                    MenuScreen(store: store)
                    
                case let .auth(store):
                    AuthScreen(store: store)
                    
                case let .profile(store):
                    ProfileScreen(store: store)
                    
                case let .settings(store):
                    SettingsScreen(store: store)
                }
            }
            .toast(isPresenting: $store.showToast) {
                AlertToast(displayMode: .hud, type: .regular, title: store.toast.message, bundle: store.localizationBundle)
            }
        }
    }
}

#Preview {
    AppView(
        store: Store(
            initialState: AppFeature.State()
        ) {
            AppFeature()
        }
    )
}
