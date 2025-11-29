//
//  QMSFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import ComposableArchitecture
import QMSClient
import PersistenceKeys
import Models
import AnalyticsClient
import NotificationsClient
import TCAExtensions
import ExyteChat

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
        var idMap: [Int: String] = [:] // Remote -> Local
        
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
            case sendMessageButtonTapped(DraftMessage)
            case urlTapped(URL)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadChat
            case chatLoaded(Result<QMSChat, any Error>)
            case messageSendError(id: String, message: String)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case handleUrl(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.qmsClient) private var qmsClient
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
                
            case let .view(.sendMessageButtonTapped(draftMessage)):
                let id: String
                
                if let index = state.messages.firstIndex(where: { $0.id == draftMessage.id }) {
                    // If this message is already exists with same id it means that it's errored out and we're retrying
                    state.messages[index].status = .sending
                    id = draftMessage.id!
                } else {
                    // If the same id doesn't exists it's a new message
                    id = UUID().uuidString
                    let localMessage = Message(
                        id: id,
                        user: User(id: String(state.userSession!.userId), name: "You", avatarURL: nil, isCurrentUser: true),
                        status: .sending,
                        createdAt: .now,
                        text: draftMessage.text
                    )
                    state.messages.append(localMessage)
                }

                return .run { [chatId = state.chatId, message = draftMessage.text] send in
                    try await qmsClient.sendQMSMessage(chatId: chatId, message: message)
                } catch: { [id, message = draftMessage.text] error, send in
                    await send(.internal(.messageSendError(id: id, message: message)))
                }
                
            case let .internal(.messageSendError(id, message)):
                let draft = DraftMessage(
                    id: id, text: message, medias: [], giphyMedia: nil, recording: nil, replyMessage: nil, createdAt: .now
                )
                let index = state.messages.firstIndex(where: { $0.id == id })!
                state.messages[index].status = .error(draft)
                return .none
                
            case let .view(.urlTapped(url)):
                return .send(.delegate(.handleUrl(url)))
                
            case .internal(.loadChat):
                return .run { [id = state.chatId] send in
                    let result = await Result { try await qmsClient.loadQMSChat(id) }
                    await send(.internal(.chatLoaded(result)))
                }
                
            case let .internal(.chatLoaded(result)):
                switch result {
                case let .success(chat):
                    state.chat = chat
                    
                    for remoteMessage in chat.messages where state.idMap[remoteMessage.id] == nil {
                        if let localMessage = state.messages.first(where: { $0.text == remoteMessage.text }) {
                            // If local messages contain same message as remote but it doesn't have an id mapping
                            // it means that it were sending and now successfully processed
                            state.idMap[remoteMessage.id] = localMessage.id
                        } else {
                            // If local messages doesn't contain a message it means we've got it from remote
                            let isCurrentUser = state.userSession!.userId == remoteMessage.senderId
                            let newLocalMessage = Message(
                                id: UUID().uuidString,
                                user: User(
                                    id: String(remoteMessage.senderId),
                                    name: isCurrentUser ? "You" : chat.partnerName,
                                    avatarURL: isCurrentUser ? nil : chat.avatarUrl ?? Links.defaultQMSAvatar,
                                    isCurrentUser: isCurrentUser
                                ),
                                status: .none,
                                createdAt: remoteMessage.date,
                                text: remoteMessage.processedText
                            )
                            state.messages.append(newLocalMessage)
                            state.idMap[remoteMessage.id] = newLocalMessage.id
                        }
                    }
                    
                    let messages = state.messages.filter { $0.user.isCurrentUser }
                    for (index, message) in messages.reversed().enumerated() {
                        if let messageIndex = state.messages.firstIndex(of: message) {
                            state.messages[messageIndex].status = index < chat.unreadCount ? .none : .sent
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
