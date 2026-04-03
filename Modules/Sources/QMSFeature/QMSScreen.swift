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
                        // send(.sendMessageButtonTapped(message))
                    } inputViewBuilder: { text, _, _, inputViewStyle, inputViewActionClosure, _ in
                        WithPerceptionTracking {
                            Group {
                                switch inputViewStyle {
                                case .message:
                                    InputView(text: text)
                                case .signature:
                                    EmptyView()
                                }
                            }
                        }
                    } messageMenuAction: { (action: ChatAction, _, message) in
                        if case .copy = action {
                            UIPasteboard.general.string = message.text
                        }
                    }
                    .keyboardDismissMode(.interactive)
                    .enableLoadMore { _ in
                        await send(.loadMoreTriggered)
                    }
                    .linkPreviewsDisabled()
                    .messageUseStyler { string in
                        return QMSBuilder(text: string).build()
                    }
                    .setAvailableInputs([.text])
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
    
    private func InputView(text: Binding<String>) -> some View {
        HStack {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                Button("+") { text.wrappedValue += "text" }
                    .buttonStyle(.borderedProminent)
            }
            #endif
            
            TextField("qms.textfield.placeholder", text: text)
                .padding()
                .background(Color(.Background.quaternary), in: .rect(cornerRadius: 16))
            
            Button {
                if !text.wrappedValue.isEmpty {
                    send(.sendMessageButtonTapped(
                        DraftMessage(text: text.wrappedValue, medias: [], giphyMedia: nil, recording: nil, replyMessage: nil, createdAt: .now)
                    ))
                }
            } label: {
                Circle()
                    .tint(Color(.Theme.primary))
                    .frame(width: 44, height: 44)
                    .overlay {
                        if store.isSending {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemSymbol: .arrowUp)
                                .bold()
                                .tint(.white)
                        }
                    }
            }
            .disabled(store.isSending)
        }
        .padding()
        .animation(.default, value: store.isSending)
        .animation(.default, value: text.wrappedValue)
        .bind(text, to: $store.draftText)
    }
}

// MARK: - Previews

#Preview {
    @Shared(.userSession) var userSession
    $userSession.withLock { $0 = .init(userId: 1, token: "", isHidden: false) }
    
    return NavigationStack {
        QMSScreen(
            store: Store(
                initialState: QMSFeature.State(chatId: 0)
            ) {
                QMSFeature()
            } withDependencies: { _ in
                
            }
        )
    }
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
