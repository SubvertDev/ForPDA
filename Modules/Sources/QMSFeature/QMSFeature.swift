//
//  QMSFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import PersistenceKeys
import Models
import ExyteChat

@Reducer
public struct QMSFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.userSession) var userSession: UserSession?
        public let chatId: Int
        public var chat: QMSChat?
        public var messages: [Message] = []
        
        public var title: String {
            if let chat {
                return chat.partnerName + " - " + chat.name
            } else {
                return ""
            }
        }
        
        public init(
            chatId: Int
        ) {
            self.chatId = chatId
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        case onDisappear
        case binding(BindingAction<State>)
        case sendMessageButtonTapped(String)
        
        case _refreshChatPeriodically
        case _loadChat
        case _chatLoaded(Result<QMSChat, any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.continuousClock) private var clock
    
    // MARK: - Cancellable
    
    private enum CancelID { case timer }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .merge([
                    .send(._loadChat),
                    .send(._refreshChatPeriodically)
                ])
                
            case .onDisappear:
                return .cancel(id: CancelID.timer)
                
            case let .sendMessageButtonTapped(message):
                return .run { [chatId = state.chatId] send in
                    try await apiClient.sendQMSMessage(chatId, message)
                    await send(._loadChat)
                }
                
            case ._refreshChatPeriodically:
                return .run { send in
                    // TODO: Remove on socket connect
                    for await _ in self.clock.timer(interval: .seconds(5)) {
                        await send(._loadChat)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case ._loadChat:
                return .run { [id = state.chatId] send in
                    let result = await Result { try await apiClient.loadQMSChat(id) }
                    await send(._chatLoaded(result))
                }
                
            case let ._chatLoaded(result):
                switch result {
                case let .success(chat):
                    // customDump(chat)
                    state.chat = chat
                    
                    for message in chat.messages {
                        if state.messages.contains(where: { $0.id == String(message.id) }) { continue }
                        let isCurrentUser = state.userSession!.userId == message.senderId
                        let newMessage = Message(
                            id: String(message.id),
                            user: User(
                                id: String(message.senderId),
                                name: isCurrentUser ? "You" : chat.partnerName,
                                avatarURL: isCurrentUser ? nil : chat.avatarUrl,
                                isCurrentUser: isCurrentUser
                            ),
                            createdAt: message.date,
                            text: message.text
                        )
                        state.messages.append(newMessage)
                    }
                    
                case let .failure(error):
                    print(error)
                    // TODO: Handle error
                }
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
