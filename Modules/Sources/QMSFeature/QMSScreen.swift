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

@ViewAction(for: QMSFeature.self)
public struct QMSScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<QMSFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<QMSFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if store.chat != nil {
                    ChatView(messages: store.messages) { message in
                        send(.sendMessageButtonTapped(message))
                    }
                    .messageUseStyler { string in
                        return QMSBuilder(text: string).build()
                    }
                    .setAvailableInputs([.text])
                    .showMessageMenuOnLongPress(false)
                    .chatTheme(
                        ChatTheme(
                            colors: ChatTheme
                                .Colors(
                                    mainBG: Color(.Background.primary),
                                    messageMyBG: Color(.Background.quaternary),
                                    messageMyText: Color(.Labels.primary),
                                    messageMyTimeText: Color(.systemGray),
                                    messageFriendBG: Color(.Background.quaternary),
                                    messageFriendText: Color(.Labels.primary),
                                    messageFriendTimeText: Color(.systemGray),
                                    statusGray: Color(.Theme.primary),
                                    sendButtonBackground: Color(.Theme.primary)
                                )
                        )
                    )
                    .environment(\.openURL, OpenURLAction(handler: { url in
                        send(.urlTapped(url))
                        return .handled
                    }))
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(store.title)
            ._toolbarTitleDisplayMode(.inline)
            .onAppear {
                send(.onAppear)
            }
        }
    }
}

#Preview {
    @Shared(.userSession) var userSession
    $userSession.withLock { $0 = .init(userId: 1, token: "", isHidden: false) }
    
    return QMSScreen(
        store: Store(
            initialState: QMSFeature.State(chatId: 0)
        ) {
            QMSFeature()
        } withDependencies: { _ in
            
        }
    )
    .environment(\.tintColor, Color(.Theme.primary))
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Error On Send") {
    @Shared(.userSession) var userSession
    $userSession.withLock { $0 = .init(userId: 1, token: "", isHidden: false) }
    
    return QMSScreen(
        store: Store(initialState: QMSFeature.State(chatId: 0)) {
            QMSFeature()
        } withDependencies: {
            $0.qmsClient = .errorOnSend
        }
    )
    .environment(\.tintColor, Color(.Theme.primary))
    .environment(\.locale, Locale(identifier: "en"))
}
