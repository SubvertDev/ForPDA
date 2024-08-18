//
//  MenuScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import SFSafeSymbols

public struct MenuScreen: View {
    
    @Perception.Bindable public var store: StoreOf<MenuFeature>
    
    public init(store: StoreOf<MenuFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            List {
                Section {
                    if let user = store.user {
                        SettingRowView(
                            title: LocalizedStringKey(user.nickname), // TODO: Remove title
                            type: .auth(user.imageUrl, user.nickname),
                            action: { store.send(.profileTapped) }
                        )
                    } else {
                        SettingRowView(
                            title: "Guest", // TODO: Remove title
                            type: .guest(.avatarDefault),
                            action: { store.send(.profileTapped) }
                        )
                    }
                }
                
                Section {
                    SettingRowView(title: "Forum", type: .symbol(.bubbleLeftAndBubbleRightFill)) {
                        store.send(.notImplementedFeatureTapped)
                    }
                    SettingRowView(title: "QMS", type: .symbol(.person2Fill)) {
                        store.send(.notImplementedFeatureTapped)
                    }
                    SettingRowView(title: "History", type: .symbol(.clockArrowCirclepath)) {
                        store.send(.notImplementedFeatureTapped)
                    }
                    SettingRowView(title: "Bookmarks", type: .symbol(.bookmarkFill)) {
                        store.send(.notImplementedFeatureTapped)
                    }
                }
                
                Section {
                    SettingRowView(title: "Settings", type: .symbol(.gearshapeFill)) { store.send(.settingsTapped)
                    }
                }
                
                Section {
                    SettingRowView(title: "App author", type: .image(._4pda)) {
                        store.send(.appAuthorButtonTapped)
                    }
                    SettingRowView(title: "App discussion", type: .image(._4pda)) {
                        store.send(.notImplementedFeatureTapped)
                    }
                    SettingRowView(title: "Changelog in Telegram", type: .image(.telegram)) {
                        store.send(.telegramChangelogButtonTapped)
                    }
                    SettingRowView(title: "Chat in Telegram", type: .image(.telegram)) {
                        store.send(.telegramChatButtonTapped)
                    }
                    SettingRowView(title: "GitHub repository", type: .image(.github)) {
                        store.send(.githubButtonTapped)
                    }
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Menu", bundle: .module))
            .task { store.send(.onTask) }
        }
    }
}

#Preview {
    NavigationStack {
        MenuScreen(
            store: Store(
                initialState: MenuFeature.State()
            ) {
                MenuFeature()
            }
        )
    }
}
