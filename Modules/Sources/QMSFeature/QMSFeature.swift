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
    
    let defaultOffset = -30
    
    // MARK: - Enums
    
    public enum LoadKind {
        case latest // initial/refresh
        case older  // pagination
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        
        @Shared(.userSession) var userSession: UserSession?
        
        public let chatId: Int
        public var chat: QMSChat?
        public var messages: [Message] = []
        var idMap: [Int: String] = [:] // Remote -> Local
        
        var isLoadingMore = false
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
            case loadMoreTriggered
            case urlTapped(URL)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadChat
            case chatLoaded(Result<QMSChat, any Error>, LoadKind)
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
                
            case .view(.loadMoreTriggered):
                guard (state.chat?.totalCount ?? defaultOffset) > abs(defaultOffset) else { return .none }
                guard !state.isLoadingMore else { return .none }
                state.isLoadingMore = true
                return .run { [id = state.chatId, chat = state.chat] send in
                    let lastMessageId = chat?.messages.first?.id ?? 0
                    let result = await Result { try await qmsClient.loadQMSChat(id, lastMessageId, defaultOffset) }
                    await send(.internal(.chatLoaded(result, .older)))
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
                    let result = await Result { try await qmsClient.loadQMSChat(id, 0, defaultOffset) }
                    await send(.internal(.chatLoaded(result, .latest)))
                }
                
            case let .internal(.chatLoaded(result, loadKind)):
                state.isLoadingMore = false
                
                switch result {
                case let .success(chat):
                    state.chat = mergeChat(state.chat, with: chat, loadKind: loadKind)
                    
                    var newLocalMessages: [Message] = []
                                        
                    for remoteMessage in chat.messages {
                        // Skip if message is already mapped
                        guard state.idMap[remoteMessage.id] == nil else { continue }
                        
                        // Matching with currently 'sending' statuses
                        if loadKind == .latest,
                           let pending = state.messages.last(
                            where: { $0.user.isCurrentUser && $0.status == .sending && $0.text == remoteMessage.processedText }
                           ) {
                            state.idMap[remoteMessage.id] = pending.id
                            continue
                        }
                        
                        // No 'sending' status, treating as remote-only message
                        let isCurrentUser = state.userSession!.userId == remoteMessage.senderId
                        let user = User(
                            id: String(remoteMessage.senderId),
                            name: isCurrentUser ? "You" : chat.partnerName,
                            avatarURL: isCurrentUser ? nil : chat.avatarUrl ?? Links.defaultQMSAvatar,
                            isCurrentUser: isCurrentUser
                        )
                        
                        let newLocalMessage = Message(
                            id: UUID().uuidString,
                            user: user,
                            status: .none,
                            createdAt: remoteMessage.date,
                            text: remoteMessage.processedText
                        )
                        
                        newLocalMessages.append(newLocalMessage)
                        state.idMap[remoteMessage.id] = newLocalMessage.id
                    }
                    
                    switch loadKind {
                    case .latest:
                        state.messages.append(contentsOf: newLocalMessages)
                    case .older:
                        state.messages.insert(contentsOf: newLocalMessages, at: 0)
                    }
                    
                    switch loadKind {
                    case .latest:
                        let messages = state.messages.filter { $0.user.isCurrentUser }
                        for (index, message) in messages.reversed().enumerated() {
                            if let messageIndex = state.messages.firstIndex(of: message) {
                                state.messages[messageIndex].status = index < chat.unreadCount ? .sent : .delivered
                            }
                        }
                    case .older:
                        let newCurrentUserMessageIds = Set(
                            newLocalMessages
                                .filter { $0.user.isCurrentUser }
                                .map(\.id)
                        )
                        for index in state.messages.indices where newCurrentUserMessageIds.contains(state.messages[index].id) {
                            state.messages[index].status = .delivered
                        }
                    }
                    
                case let .failure(error):
                    analyticsClient.capture(error)
                    state.alert = .somethingWentWrong
                }
                
                reportFullyDisplayed(&state)
                return .run { _ in
                    let ids = (try? result.get().id).map { [$0] } ?? []
                    await notificationsClient.removeNotifications(ids: ids)
                }
                
            case .binding:
                return .none
            }
        }
        ._printChanges()
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
    
    private func mergeChat(_ existing: QMSChat?, with incoming: QMSChat, loadKind: LoadKind) -> QMSChat {
        guard let existing else { return incoming }
        
        var merged = incoming
        let existingIds = Set(existing.messages.map(\.id))
        let incomingIds = Set(incoming.messages.map(\.id))
        
        switch loadKind {
        case .latest:
            let missingOlderMessages = existing.messages.filter { !incomingIds.contains($0.id) }
            merged.messages = missingOlderMessages + incoming.messages
            
        case .older:
            let missingOlderMessages = incoming.messages.filter { !existingIds.contains($0.id) }
            merged.messages = missingOlderMessages + existing.messages
        }
        
        return merged
    }
}
