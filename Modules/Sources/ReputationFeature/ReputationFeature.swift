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
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination: Hashable {
        case alert(AlertState<Alert>)
        
        public enum Alert { case ok }
    }
    
    // MARK: - Picker Section
    
    enum PickerSection: Int {
        case history = 1
        case votes = 2
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        
        public let userId: Int
        public var isLoading = true
        public var historyData: [ReputationVote] = []
        var pickerSection: PickerSection = .history
        
        public var loadAmount = 20
        public var offset = 0
        
        public init(userId: Int) {
            self.userId = userId
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case destination(PresentationAction<Destination.Action>)
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            case loadMore
            case refresh
            case profileTapped(Int)
            case sourceTapped(ReputationVote)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadData
            case historyResponse(Result<ReputationVotes, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openProfile(profileId: Int)
            case openTopic(topicId: Int, name: String, goTo: GoTo)
            case openArticle(articleId: Int)
        }
    }
    
    // MARK: - CancelID
    
    enum CancelID {
        case loadData
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.pickerSection):
                state.historyData = []
                state.offset = 0
                state.isLoading = true
                return .send(.internal(.loadData))
                    .merge(with: .cancel(id: CancelID.loadData))
                
            case .view(.onAppear):
                return .send(.internal(.loadData))
                
            case .view(.loadMore):
                guard !state.isLoading else { return .none }
                guard !state.historyData.isEmpty else { return .none }
                return .send(.internal(.loadData))
                
            case .view(.refresh):
                state.offset = 0
                return .send(.internal(.loadData))
                
            case let .view(.profileTapped(profileId)):
                return .send(.delegate(.openProfile(profileId: profileId)))
                
            case let .view(.sourceTapped(vote)):
                switch vote.createdIn {
                case .profile:
                    return .send(.delegate(.openProfile(profileId: vote.authorId)))
                    
                case let .topic(id: topicId, topicName: topicName, postId: postId):
                    return .send(.delegate(.openTopic(topicId: topicId, name: topicName, goTo: .post(id: postId))))
                    
                case let .site(id: articleId, _, _):
                    return .send(.delegate(.openArticle(articleId: articleId)))
                }
                
            case .internal(.loadData):
                let isHistory = state.pickerSection == .history
                return .run { [userId = state.userId, offset = state.offset, amount = state.loadAmount] send in
                    let request = ReputationVotesRequest(
                        userId: userId,
                        type: isHistory ? .to : .from,
                        offset: offset,
                        amount: amount
                    )
                    let result = await Result {
                        try await apiClient.getReputationVotes(data: request)
                    }
                    await send(.internal(.historyResponse(result)))
                }
                .cancellable(id: CancelID.loadData)
                
            case let .internal(.historyResponse(.success(votes))):
                if state.offset == 0 {
                    state.historyData.removeAll()
                }
                state.historyData.append(contentsOf: votes.votes)
                state.offset += state.loadAmount
                state.isLoading = false
                return .none
                
            case let .internal(.historyResponse(.failure(error))):
                state.isLoading = false
                state.destination = .alert(.error)
                print("Error \(error)")
                return .none
                
            case .delegate, .binding, .destination:
                return .none
                
            }
        }
    }
}

// MARK: - Alert Extension

extension AlertState where Action == ReputationFeature.Destination.Alert {
    nonisolated(unsafe) static let error = Self {
        TextState("Whoops!", bundle: .module)
    } actions: {
        ButtonState(role: .cancel, action: .ok) {
            TextState("OK")
        }
    } message: {
        TextState("Something went wrong while loading reputation :(", bundle: .module)
    }
}
