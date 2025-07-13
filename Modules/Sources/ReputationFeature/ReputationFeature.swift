//
//  ReputationFeature.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 11.07.2025.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct ReputationFeature: Reducer, Sendable {
    
    public init() {}
    
    enum PickerSelection: Int {
        case history = 1
        case votes = 2
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        
        public var isLoading = false
        public var historyData: Models.ReputationVotes?
        var pickerSelection: PickerSelection = .history
        
        public init() {}
        
    }
    
    // MARK: - Action
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadHistory
            case historyResponse(Result<ReputationVotes, any Error>)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                if state.pickerSelection == .history {
                    return .send(.internal(.loadHistory))
                } else {
                    print("is onAppear votes")
                }
                return .none
                
            case .internal(.loadHistory):
                return .run { send in
                    let result = await Result {
                        try await apiClient.getReputationVotes(data: ReputationVotesRequest(userId: 6176341, type: .from, offset: 0, amount: 10))
                    }
                    await send(.internal(.historyResponse(result)))
                }
                
            case .internal(.historyResponse(let result)):
                state.isLoading = false
                switch result {
                case .success(let votes):
                    state.historyData = votes
                    
                case .failure(let error):
                    print("error \(error)")
                }
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
