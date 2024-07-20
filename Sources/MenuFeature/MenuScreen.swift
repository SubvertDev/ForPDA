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
                        title: store.loggedIn ? "Никнейм" : "Гость",
                        type: .auth(
                            store.loggedIn ? ._4pda : .avatarDefault,
                            store.loggedIn ? "Никнейм" : nil
                        ),
                        action: { store.send(.profileTapped) }
                    )
                }
                
                Section {
                    SettingRowView(title: "История", type: .symbol(.clockArrowCirclepath)) {}
                    SettingRowView(title: "Закладки", type: .symbol(.bookmarkFill)) {}
                }
                .disabled(true)
                
                Section {
                    SettingRowView(title: "Настройки", type: .symbol(.gearshapeFill)) { store.send(.settingsTapped)
                    }
                }
                
                Section {
                    SettingRowView(title: "Автор приложения", type: .image(._4pda)) {}
                    SettingRowView(title: "Обсуждение приложения", type: .image(._4pda)) {}
                        .disabled(true)
                    SettingRowView(title: "Список изменений в Telegram", type: .image(.telegram)) {}
                    SettingRowView(title: "Чат приложения в Telegram", type: .image(.telegram)) {}
                    SettingRowView(title: "GitHub репозиторий", type: .image(.github)) {}
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
        .navigationTitle("Настройки")
    }
}
