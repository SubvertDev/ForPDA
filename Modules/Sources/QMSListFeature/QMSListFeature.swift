//
//  QMSListFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import CacheClient
import ComposableArchitecture
import Foundation
import Models
import QMSClient

@Reducer
public struct QMSListFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Enums
    
    public enum ViewState: Equatable {
        case loaded(QMSList)
        case loading
        case empty
        case error
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var createChat: CreateChatFeature.State?
        var viewState: ViewState
        public var qms: QMSList?
        var expandedGroups: [Bool] = []
        
        public init(
            viewState: ViewState = .loading
        ) {
            self.viewState = viewState
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            public enum UserContextMenu {
                case createChatButtonTapped
                case userProfileButtonTapped
                case profileLinkButtonTapped
                case addToBlacklistButtonTapped
                case deleteAllChatsButtonTapped
            }
            
            public enum ChatContextMenu {
                case markAsReadButtonTapped
                case deleteChatButtonTapped
            }
            
            case onAppear
            case onRefresh
            case userRowTapped(Int)
            case userContextMenu(UserContextMenu, QMSUser)
            case chatRowTapped(Int)
            case chatContextMenu(ChatContextMenu, Int, Int) // ChatID, UserID
            case createChatButtonTapped(user: QMSUser?)
            case tryAgainButtonTapped
        }
        
        case createChat(PresentationAction<CreateChatFeature.Action>)
        case alert(PresentationAction<Alert>)
        public enum Alert: Equatable {
            case confirmDeleteChat(chatId: Int, userId: Int)
            case confirmDeleteAllChats(userId: Int)
            case cancel
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadQMS
            case qmsLoaded(Result<QMSList, any Error>)
            case loadUser(_ id: Int)
            case userLoaded(Result<QMSUser, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openQMSChat(Int)
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.notificationsClient) private var notificationsClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.qmsClient) private var qmsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.expandedGroups) { oldState, state in
                    .run { [after = state.expandedGroups, qms = state.qms] send in
                        func changedIndex(before: [Bool], after: [Bool]) -> Int? {
                            guard before.count == after.count else { return nil }
                            for index in before.indices {
                                if before[index] == false && after[index] == true {
                                    return index
                                }
                            }
                            return nil
                        }
                        if let index = changedIndex(before: oldState, after: after),
                           let userId = qms?.users[index].userId,
                           userId != 0 {
                            await send(.internal(.loadUser(userId)))
                        }
                    }
            }
        
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Binding
                
            case .binding:
                return .none

            case let .alert(.presented(.confirmDeleteChat(chatId: chatId, userId: userId))):
                return .run { send in
                    let _ = try await qmsClient.deleteChat(id: chatId)
                    await send(.internal(.loadUser(userId)))
                }
                
            case let .alert(.presented(.confirmDeleteAllChats(userId: userId))):
                return .run { send in
                    let _ = try await qmsClient.deleteChat(id: userId)
                    await send(.internal(.loadUser(userId)))
                }

            case .alert:
                return .none
                
                // MARK: - View
                
            case .view(.onAppear):
                return .run { send in
                    await send(.internal(.loadQMS))
                    
                    // TODO: Does this cancel on feature removal?
                    for await unread in notificationsClient.unreadPublisher().values.dropFirst() {
                        guard unread.qmsUnreadCount > 0 else { continue }
                        await send(.internal(.loadQMS))
                    }
                }
                
            case .view(.onRefresh):
                return .run { send in
                    await send(.internal(.loadQMS))
                }
                
            case let .view(.userRowTapped(userId)):
                guard let qms = state.qms else { return .none }
                guard let index = qms.users.firstIndex(where: { $0.id == userId }) else { return .none }
                
                state.expandedGroups[index].toggle()
                
                return .run { send in
                    guard userId != 0 else { return }
                    await send(.internal(.loadUser(userId)))
                }
                
            case let .view(.userContextMenu(userContextAction, user)):
                switch userContextAction {
                case .createChatButtonTapped:
                    break
                case .userProfileButtonTapped:
                    break
                case .profileLinkButtonTapped:
                    break
                case .addToBlacklistButtonTapped:
                    break
                case .deleteAllChatsButtonTapped:
                    state.alert = .deleteAllChatsConfirmation(userId: user.id)
                }
                return .none
                
            case let .view(.chatRowTapped(id)):
                return .send(.delegate(.openQMSChat(id)))
                
            case let .view(.chatContextMenu(chatContextAction, chatId, userId)):
                switch chatContextAction {
                case .markAsReadButtonTapped:
                    break
                case .deleteChatButtonTapped:
                    state.alert = .deleteChatConfirmation(chatId: chatId, userId: userId)
                }
                return .none
                
            case let .view(.createChatButtonTapped(user)):
                state.createChat = CreateChatFeature.State(user: user)
                return .none
                
            case .view(.tryAgainButtonTapped):
                state.viewState = .loading
                return .send(.internal(.loadQMS))
                
                // MARK: - Destinations
                
            case let .createChat(.presented(.delegate(.chatCreated(userId: userId)))):
                guard let qms = state.qms else { return .none }
                if qms.users.contains(where: { $0.userId == userId }) {
                    return .run { send in
                        await send(.internal(.loadUser(userId)))
                    }
                } else {
                    return .send(.internal(.loadQMS))
                }
                
            case .createChat:
                return .none
                
                // MARK: - Internal
                
            case .internal(.loadQMS):
                return .run { send in
                    let result = await Result { try await qmsClient.loadChatList() }
                    await send(.internal(.qmsLoaded(result)))
                }
                
            case let .internal(.qmsLoaded(result)):
                switch result {
                case let .success(qms):
                    var qms = qms
                    // customDump(qms)
                    
                    if state.expandedGroups.count != qms.users.count {
                        let previousExpandedGroups = state.expandedGroups
                        state.expandedGroups = qms.users.indices.map { index in
                            previousExpandedGroups.indices.contains(index) ? previousExpandedGroups[index] : false
                        }
                    }
                    
                    for (index, user) in qms.users.enumerated() where user.chats.isEmpty {
                        if let cachedChats = cacheClient.getQMSChats(user.id) {
                            qms.users[index].chats = cachedChats
                        }
                    }
                    
                    state.qms = qms
                    state.viewState = qms.users.isEmpty ? .empty : .loaded(qms)
                    
                case let .failure(error):
                    print(error)
                    state.viewState = .error
                }
                analyticsClient.reportFullyDisplayed()
                return .none
                
            case let .internal(.loadUser(userId)):
                return .run { send in
                    let result = await Result { try await qmsClient.loadUser(id: userId) }
                    await send(.internal(.userLoaded(result)))
                }
                
            case let .internal(.userLoaded(result)):
                switch result {
                case let .success(user):
                    if var qms = state.qms,
                       let index = qms.users.firstIndex(where: { $0.id == user.id }) {
                        qms.users[index].chats = user.chats.sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
                        state.qms = qms
                        cacheClient.setQMSChats(qms.users[index].id, user.chats)
                        state.viewState = .loaded(qms)
                    }
                    
                case let .failure(error):
                    print(error)
                    state.viewState = .error
                }
                return .none
                
                // MARK: - Delegate
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$createChat, action: \.createChat) {
            CreateChatFeature()
        }
        .ifLet(\.$alert, action: \.alert)
        
        Analytics()
    }
}

// MARK: - Alert Extensions

private extension AlertState where Action == QMSListFeature.Action.Alert {
    static func deleteChatConfirmation(chatId: Int, userId: Int) -> Self {
        AlertState {
            TextState("Delete chat?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteChat(chatId: chatId, userId: userId)) {
                TextState("Delete", bundle: .module)
            }
            ButtonState(role: .cancel, action: .cancel) {
                TextState("Cancel", bundle: .module)
            }
        } message: {
            TextState("This action cannot be undone", bundle: .module)
        }
    }
    
    static func deleteAllChatsConfirmation(userId: Int) -> Self {
        AlertState {
            TextState("Delete all chats?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteAllChats(userId: userId)) {
                TextState("Delete", bundle: .module)
            }
            ButtonState(role: .cancel, action: .cancel) {
                TextState("Cancel", bundle: .module)
            }
        } message: {
            TextState("This action cannot be undone", bundle: .module)
        }
    }
}
