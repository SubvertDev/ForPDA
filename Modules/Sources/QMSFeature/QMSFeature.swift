//
//  QMSFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
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
        
        var hasMoreOlderMessages = true
        var isLoadingMore = false
        var didLoadOnce = false
        var isSending = false
        
        var draftText = ""
        
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
            case messageSendError(any Error)
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
        BindingReducer()
        
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
                guard !state.isSending, !draftMessage.text.isEmpty else { return .none }
                
                state.isSending = true
                
                return .run { [chatId = state.chatId, message = draftMessage.text] send in
                    try await qmsClient.sendQMSMessage(chatId: chatId, message: message)
                } catch: { error, send in
                    await send(.internal(.messageSendError(error)))
                }
                
            case .view(.loadMoreTriggered):
                guard !state.isLoadingMore else { return .none }
                guard state.hasMoreOlderMessages else { return .none }
                guard (state.chat?.totalCount ?? defaultOffset) > abs(defaultOffset) else { return .none }
                state.isLoadingMore = true
                return .run { [id = state.chatId, chat = state.chat] send in
                    let lastMessageId = chat?.messages.first?.id ?? 0
                    let result = await Result { try await qmsClient.loadQMSChat(id, lastMessageId, defaultOffset) }
                    await send(.internal(.chatLoaded(result, .older)))
                }
                
            case let .internal(.messageSendError(error)):
                state.isSending = false
                state.alert = .somethingWentWrong
                analyticsClient.capture(error)
                return .none
                
            case let .view(.urlTapped(url)):
                guard url.absoluteString.contains("act=findpost"),
                      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let act = components.queryItems?.first(where: { $0.name == "act" })?.value,
                      act == "findpost",
                      let pidRaw = components.queryItems?.first(where: { $0.name == "pid"})?.value,
                      let pid = Int(pidRaw)
                else {
                    return .send(.delegate(.handleUrl(url)))
                }
                
                return .run { send in
                    @Dependency(\.apiClient) var api
                    let request = JumpForumRequest(postId: pid, topicId: 0, allPosts: true, type: .post)
                    let response = try await api.jumpForum(request: request)
                    let url = URL(string: "https://4pda.to/forum/index.php?showtopic=\(response.id)&view=findpost&p=\(response.postId)")!
                    await send(.delegate(.handleUrl(url)))
                }
                
            case .internal(.loadChat):
                return .run { [id = state.chatId] send in
                    let result = await Result { try await qmsClient.loadQMSChat(id, 0, defaultOffset) }
                    await send(.internal(.chatLoaded(result, .latest)))
                }
                
            case let .internal(.chatLoaded(result, loadKind)):
                state.draftText = ""
                state.isSending = false
                state.isLoadingMore = false
                
                switch result {
                case let .success(chat):
                    let existingRemote = state.chat?.messages ?? []
                    let mergeResult = mergeRemoteMessages(
                        existing: existingRemote,
                        incoming: chat.messages,
                        loadKind: loadKind
                    )
                    
                    var mergedChat = chat
                    mergedChat.messages = mergeResult.messages
                    
                    state.messages = makeLocalMessages(
                        from: mergeResult.messages,
                        chat: mergedChat,
                        currentUserId: state.userSession!.userId
                    )
                    state.chat = mergedChat
                    
                    if mergeResult.messages.count >= chat.totalCount {
                        state.hasMoreOlderMessages = false
                    } else if loadKind == .older, mergeResult.uniqueIncomingCount == 0 {
                        state.hasMoreOlderMessages = false
                    } else {
                        state.hasMoreOlderMessages = true
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
    }
    
    // MARK: - Shared Logic
    
    private struct RemoteMergeResult {
        let messages: [QMSMessage]
        let uniqueIncomingCount: Int
    }
    
    private func mergeRemoteMessages(
        existing: [QMSMessage],
        incoming: [QMSMessage],
        loadKind _: LoadKind
    ) -> RemoteMergeResult {
        let existingIds = Set(existing.map(\.id))
        var seenIncomingIds = Set<Int>()
        var uniqueIncomingCount = 0
        
        for message in incoming {
            if !existingIds.contains(message.id), seenIncomingIds.insert(message.id).inserted {
                uniqueIncomingCount += 1
            }
        }
        
        var messagesById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for message in incoming {
            messagesById[message.id] = message
        }
        
        let mergedMessages = messagesById.values.sorted {
            if $0.date == $1.date {
                return $0.id < $1.id
            }
            return $0.date < $1.date
        }
        
        return RemoteMergeResult(messages: mergedMessages, uniqueIncomingCount: uniqueIncomingCount)
    }
    
    private func makeLocalMessages(
        from remoteMessages: [QMSMessage],
        chat: QMSChat,
        currentUserId: Int
    ) -> [Message] {
        var localMessages = remoteMessages.map { remoteMessage in
            let isCurrentUser = currentUserId == remoteMessage.senderId
            let user = User(
                id: String(remoteMessage.senderId),
                name: isCurrentUser ? "You" : chat.partnerName,
                avatarURL: isCurrentUser ? nil : chat.avatarUrl ?? Links.defaultQMSAvatar,
                isCurrentUser: isCurrentUser
            )
            
            return Message(
                id: String(remoteMessage.id),
                user: user,
                status: .none,
                createdAt: remoteMessage.date,
                text: remoteMessage.processedText
            )
        }
        
        for index in localMessages.indices {
            guard localMessages[index].user.isCurrentUser else { continue }
            localMessages[index].status = .read
        }
        
        for index in localMessages.indices.suffix(chat.unreadCount) {
            guard localMessages[index].user.isCurrentUser else { continue }
            localMessages[index].status = .sent
        }
        
        return localMessages
    }
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}
