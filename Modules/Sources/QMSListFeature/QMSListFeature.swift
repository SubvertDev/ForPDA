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
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var qms: QMSList?
        public var expandedGroups: [Bool] = []
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            case chatRowTapped(Int)
            case userRowTapped(Int)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case load
            case qmsLoaded(Result<QMSList, any Error>)
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
                                let result = await Result { try await qmsClient.loadQMSUser(id: userId) }
                                await send(.internal(.userLoaded(result)))
                        }
                    }
            }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding, .delegate:
                return .none
                
            case .view(.onAppear):
                return .run { send in
                    await send(.internal(.load))

                    // TODO: Does this cancel on feature removal?
                    for await unread in notificationsClient.unreadPublisher().values {
                        guard unread.qmsUnreadCount > 0 else { continue }
                        await send(.internal(.load))
                    }
                }

            case let .view(.chatRowTapped(id)):
                return .send(.delegate(.openQMSChat(id)))
                
            case let .view(.userRowTapped(id)):
                guard let qms = state.qms else { return .none }
                guard let index = qms.users.firstIndex(where: { $0.id == id }) else { return .none }
                
                state.expandedGroups[index].toggle()
                
                guard state.expandedGroups[index] else { return .none }
                
                return .run { send in
                    guard id != 0 else { return }
                    let result = await Result { try await qmsClient.loadQMSUser(id) }
                    await send(.internal(.userLoaded(result)))
                }
                
            case .internal(.load):
                return .run { send in
                    let result = await Result { try await qmsClient.loadQMSList() }
                    await send(.internal(.qmsLoaded(result)))
                }
                
            case let .internal(.qmsLoaded(result)):
                switch result {
                case let .success(qms):
                    var qms = qms
                    // customDump(qms)
                    
                    if qms.users.count > state.qms?.users.count ?? 0 {
                        state.expandedGroups.removeAll()
                        qms.users.forEach { _ in state.expandedGroups.append(false) }
                    }
                    
                    for (index, user) in qms.users.enumerated() where user.chats.isEmpty {
                        if let cachedChats = cacheClient.getQMSChats(user.id) {
                            qms.users[index].chats = cachedChats
                        }
                    }
                    
                    state.qms = qms
                    
                case let .failure(error):
                    print(error)
                }
                analyticsClient.reportFullyDisplayed()
                return .none
                
            case let .internal(.userLoaded(result)):
                switch result {
                case let .success(user):
                    if var qms = state.qms,
                       let index = qms.users.firstIndex(where: { $0.id == user.id }) {
                        qms.users[index].chats = user.chats.sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
                        state.qms = qms
                        cacheClient.setQMSChats(qms.users[index].id, user.chats)
                    }
                    
                case let .failure(error):
                    print(error)
                }
                return .none
            }
        }
        
        // Disabled until redesign
        // Analytics()
    }
    
    // MARK: - Shared Logic
    }
