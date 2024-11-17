//
//  QMSScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import SFSafeSymbols
import ExyteChat

public struct QMSScreen: View {
    
    @Perception.Bindable public var store: StoreOf<QMSFeature>
    
    public init(store: StoreOf<QMSFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                    .ignoresSafeArea()
                
                if store.chat != nil {
                    ChatView(messages: store.messages) { message in
                        store.send(.sendMessageButtonTapped(message.text))
                    }
                    .setAvailableInput(.textOnly)
                    .showMessageMenuOnLongPress(false)
                    .chatTheme(ChatTheme(colors: ChatTheme.Colors(mainBackground: Color.Background.primary)))
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(store.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await store.send(.onAppear).finish()
            }
//            .onAppear {
//                store.send(.onAppear)
//            }
//            .onDisappear {
//                store.send(.onDisappear)
//            }
        }
    }
}

#Preview {
    QMSScreen(store: Store(initialState: QMSFeature.State(chatId: 0)) {
        QMSFeature()
    })
}
