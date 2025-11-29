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
    
    public enum Action: BindableAction {
        case onAppear
        case binding(BindingAction<State>)
        
        case chatRowTapped(Int)
        case userRowTapped(Int)
        
        case _qmsLoaded(Result<QMSList, any Error>)
        case _userLoaded(Result<QMSUser, any Error>)
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
            case .onAppear:
                return .run { send in
                    let result = await Result { try await qmsClient.loadQMSList() }
                    await send(._qmsLoaded(result))
                }
                
            case .binding:
                return .none
                
            case .chatRowTapped:
                return .none
                
            case let .userRowTapped(id):
                // Refactor later
                if let qms = state.qms,
                   let user = qms.users.first(where: { $0.id == id }) {
                    if user.chats.isEmpty {
                        return .run { send in
                            let result = await Result { try await qmsClient.loadQMSUser(id) }
                            await send(._userLoaded(result))
                        }
                    } else if let index = qms.users.firstIndex(of: user) {
                        state.expandedGroups[index].toggle()
                    }
                }
                return .none
                
            case let ._qmsLoaded(result):
                switch result {
                case let .success(qms):
                    var qms = qms
                    // customDump(qms)
                    
                    // Populating expandedGroups on first load
                    // Refactor later
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
                
            case let ._userLoaded(result):
                switch result {
                case let .success(user):
                    
                    // Refactor later
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
