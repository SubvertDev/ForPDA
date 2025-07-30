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
        public var historyData: ReputationVotes?
        var pickerSelection: PickerSelection = .history
        
        public var loadAmount: Int = 20
        public var offset: Int = 0
        
        public init() {}
    }
    
    // MARK: - Action
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            case loadMore
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadData(isHistory: Bool)
            case historyResponse(Result<ReputationVotes, any Error>)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Shared(.userSession) var userSession
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                state.offset = 0
                switch state.pickerSelection {
                case .history:
                    return .send(.internal(.loadData(isHistory: true)))
                case .votes:
                    return .send(.internal(.loadData(isHistory: false)))
                }
                
            case .view(.loadMore):
                guard !state.isLoading else { return .none }
                guard state.historyData?.votes.isEmpty == false else { return .none }
                state.isLoading = true
                switch state.pickerSelection {
                case .history:
                    return .send(.internal(.loadData(isHistory: true)))
                case .votes:
                    return .send(.internal(.loadData(isHistory: false)))
                }
                
            case let .internal(.loadData(isHistory)):
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    let request = ReputationVotesRequest(
                        userId: 236113,
                        type: isHistory ? .from : .to,
                        offset: offset,
                        amount: amount
                    )
                    let result = await Result {
                        try await apiClient.getReputationVotes(data: request)
                    }
                    await send(.internal(.historyResponse(result)))
                }
                
            case let .internal(.historyResponse(.success(votes))):
                state.isLoading = false
                
                if state.offset == 0 {
                    state.historyData = votes
                } else {
                    state.historyData?.votes.append(contentsOf: votes.votes)
                    state.historyData?.votesCount = votes.votesCount
                }
                
                state.offset += state.loadAmount
                return .none
                
            case let .internal(.historyResponse(.failure(error))):
                state.isLoading = false
                print("Error \(error)")
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
