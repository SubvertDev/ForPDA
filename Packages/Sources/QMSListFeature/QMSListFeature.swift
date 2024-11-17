//
//  QMSListFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct QMSListFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var qms: QMSList?
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        case binding(BindingAction<State>)
        
        case chatRowTapped(Int)
        case userRowTapped(Int)
        
        case _qmsLoaded(Result<QMSList, any Error>)
    }
    
    // MARK: - Dependency
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let result = await Result { try await apiClient.loadQMSList() }
                    await send(._qmsLoaded(result))
                }
                
            case .binding:
                return .none
                
            case .chatRowTapped, .userRowTapped:
                return .none
                
            case let ._qmsLoaded(result):
                switch result {
                case let .success(qms):
                    // customDump(qms)
                    state.qms = qms
                    
                case let .failure(error):
                    print(error)
                }
                return .none
            }
        }
    }
}
