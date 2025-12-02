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
        var didLoadOnce = false
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
            case qmsLoaded(Result<QMSList, any Error>)
            case userLoaded(Result<QMSUser, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openQMSChat(Int)
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.qmsClient) private var qmsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding, .delegate:
                return .none
                
            case .view(.onAppear):
                return .run { send in
                    let result = await Result { try await qmsClient.loadQMSList() }
                    await send(.internal(.qmsLoaded(result)))
                }

            case let .view(.chatRowTapped(id)):
                return .send(.delegate(.openQMSChat(id)))
                
            case let .view(.userRowTapped(id)):
                // Refactor later
                if let qms = state.qms,
                   let user = qms.users.first(where: { $0.id == id }) {
                    if user.chats.isEmpty {
                        return .run { send in
                            let result = await Result { try await qmsClient.loadQMSUser(id) }
                            await send(.internal(.userLoaded(result)))
                        }
                    } else if let index = qms.users.firstIndex(of: user) {
                        state.expandedGroups[index].toggle()
                    }
                }
                return .none
                
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
                reportFullyDisplayed(&state)
                return .none
                
            case let .internal(.userLoaded(result)):
                switch result {
                case let .success(user):
                    if var qms = state.qms,
                       let index = qms.users.firstIndex(where: { $0.id == user.id }) {
                        qms.users[index].chats = user.chats
                        state.qms = qms
                        cacheClient.setQMSChats(qms.users[index].id, user.chats)
                    }
                    
                case let .failure(error):
                    print(error)
                }
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
