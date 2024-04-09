//
//  App.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2024.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Main

@main
struct ForPdaApp: App {
    
    let store = Store(
        initialState: AppFeature.State()
    ) {
        AppFeature()
    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}

// MARK: - Feature

@Reducer
struct AppFeature {
    
    @Reducer
    enum Path {
        case menu(MenuFeature)
        case news(NewsFeature)
    }
    
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var newsList = NewsListFeature.State()
    }
    
    enum Action {
        case path(StackActionOf<Path>)
        case newsList(NewsListFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.newsList, action: \.newsList) {
            NewsListFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .path:
                return .none
                
            case .newsList(.menuTapped):
                state.path.append(.menu(MenuFeature.State()))
                return .none
                
            case .newsList:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

// MARK: - View

struct AppView: View {
    
    @Perception.Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                NewsListView(store: store.scope(state: \.newsList, action: \.newsList))
            } destination: { store in
                switch store.case {
                case let .menu(store):
                    let _ = print(store)
                    MenuViewSUI()
                    
                case let .news(store):
                    NewsViewSUI(store: store)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    AppView(
        store: Store(
            initialState: AppFeature.State()
        ) {
            AppFeature()
        }
    )
}
