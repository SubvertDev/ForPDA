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
                    SettingRowView(
                        title: store.loggedIn ? "Nickname" : "Guest",
                        type: .auth(
                            store.loggedIn ? ._4pda : .avatarDefault,
                            store.loggedIn ? "Nickname" : nil
                        ),
                        action: { store.send(.profileTapped) }
                    )
                }
                
                Section {
                    SettingRowView(title: "History", type: .symbol(.clockArrowCirclepath)) {}
                    SettingRowView(title: "Bookmarks", type: .symbol(.bookmarkFill)) {}
                }
                .disabled(true)
                
                Section {
                    SettingRowView(title: "Settings", type: .symbol(.gearshapeFill)) { store.send(.settingsTapped)
                    }
                }
                
                Section {
                    SettingRowView(title: "App author", type: .image(._4pda)) {}
                    SettingRowView(title: "App discussion", type: .image(._4pda)) {}
                        .disabled(true)
                    SettingRowView(title: "Changelog in Telegram", type: .image(.telegram)) {}
                    SettingRowView(title: "Chat in Telegram", type: .image(.telegram)) {}
                    SettingRowView(title: "GitHub repository", type: .image(.github)) {}
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MenuScreen(
            store: Store(
                initialState: MenuFeature.State(
                    loggedIn: false
                )
            ) {
                MenuFeature()
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Menu")
    }
}
