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
import AnalyticsClient
import NotificationsClient
import TCAExtensions

@Reducer
public struct QMSFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        
        @Shared(.userSession) var userSession: UserSession?
        
        public let chatId: Int
        public var chat: QMSChat?
        public var messages: [Message] = []
        
        var didLoadOnce = false
        
        public var title: String {
            if let chat {
                return chat.partnerName + " - " + chat.name
            } else {
                return ""
            }
        }
        
        public init(chatId: Int) {
            self.chatId = chatId
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case alert(PresentationAction<Alert>)
        public enum Alert {
            case ok
        }
        
        case view(View)
        public enum View {
            case onAppear
            case sendMessageButtonTapped(String)
            case urlTapped(URL)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadChat
            case chatLoaded(Result<QMSChat, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case handleUrl(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.notificationCenter) private var notificationCenter
    @Dependency(\.notificationsClient) private var notificationsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .alert, .delegate:
                return .none
                
            case .view(.onAppear):
                return .merge([
                    .send(.internal(.loadChat)),
                    .run { send in
                        for await _ in notificationCenter.notifications(named: .sceneBecomeActive) {
                            await send(.internal(.loadChat))
                        }
                    },
                    .run { [chatId = state.chatId] send in
                        for await notification in notificationsClient.eventPublisher().values {
                            if case let .qms(id) = notification, chatId == id {
                                await send(.internal(.loadChat))
                            }
                        }
                    }
                ])
                
            case let .view(.sendMessageButtonTapped(message)):
                // let sendingMessage = Message(
                //     id: message,
                //     user: User(id: String(state.userSession!.userId), name: "You", avatarURL: nil, isCurrentUser: true),
                //     status: .sending,
                //     createdAt: .now,
                //     text: message
                // )
                // state.messages.append(sendingMessage)
                return .run { [chatId = state.chatId] send in
                    try await apiClient.sendQMSMessage(chatId, message)
                }
                
            case let .view(.urlTapped(url)):
                return .send(.delegate(.handleUrl(url)))
                
            case .internal(.loadChat):
                return .run { [id = state.chatId] send in
                    let result = await Result { try await apiClient.loadQMSChat(id) }
                    await send(.internal(.chatLoaded(result)))
                }
                
            case let .internal(.chatLoaded(result)):
                switch result {
                case let .success(chat):
                    state.chat = chat
                    
                    for message in chat.messages {
                        // Skip already processed messages while setting them status to sent
                        if state.messages.contains(where: { $0.id == String(message.id) }) { continue }
                        if let msgIndex = state.messages.firstIndex(where: { $0.id == String(message.id) }) {
                            state.messages[msgIndex].status = .sent
                            continue
                        }
                        
                        // Set .none status on sent messages and skip
                        if let index = state.messages.firstIndex(where: { $0.id == message.text }) {
                            state.messages[index].status = .none
                            continue
                        }
                        
                        // Creating new messages
                        let isCurrentUser = state.userSession!.userId == message.senderId
                        let newMessage = Message(
                            id: String(message.id),
                            user: User(
                                id: String(message.senderId),
                                name: isCurrentUser ? "You" : chat.partnerName,
                                avatarURL: isCurrentUser ? nil : chat.avatarUrl ?? Links.defaultQMSAvatar,
                                isCurrentUser: isCurrentUser
                            ),
                            status: .sent,
                            createdAt: message.date,
                            text: message.processedText
                        )
                        state.messages.append(newMessage)
                    }
                    
                    // Setting non-read status for our messages if we have an unread count
                    let myMessages = state.messages.filter { $0.user.isCurrentUser }
                    for (index, message) in myMessages.reversed().enumerated() where index < chat.unreadCount {
                        if let messageIndex = state.messages.firstIndex(of: message) {
                            state.messages[messageIndex].status = .none
                        }
                    }
                    
                case let .failure(error):
                    analyticsClient.capture(error)
                    state.alert = .somethingWentWrong
                }
                
                reportFullyDisplayed(&state)
                return .none
                
            case .binding:
                return .none
            }
        }
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}
