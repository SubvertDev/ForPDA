//
//  ForumMergeFeature.swift
//  ForPDA
//
//  Created by Xialtal on 30.09.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import ToastClient

@Reducer
public struct ForumMergeFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localization
    
    private enum Localization {
        static let errorMergingTopics = LocalizedStringResource("Error merging topics", bundle: .module)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let type: ForumMergeType
        
        public var topics: [TopicInfo] = []
        
        public var targetTopicId = 0
        
        var isSending = false
        
        var isMergeButtonDisabled: Bool {
            return true
        }
        
        public init(
            type: ForumMergeType
        ) {
            self.type = type
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            
            case mergeButtonTapped
            case closeButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case mergeTopics([Int])
            
            case mergeTopicsResponse(Result<Int, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openTopic(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.toastClient) private var toastClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                switch state.type {
                case .posts(_):
                    break
                    
                case let .topics(topics):
                    state.targetTopicId = topics.first?.id ?? 0
                }
                return .none
                
            case .view(.closeButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.mergeButtonTapped):
                switch state.type {
                case .posts:
                    break
                    
                case let .topics(topics):
                    let ids = topics.map { $0.id }
                    return .send(.internal(.mergeTopics(ids)))
                }
                return .none
                
            case let .internal(.mergeTopics(ids)):
                state.isSending = true
                return .run { [targetId = state.targetTopicId] send in
                    let topicId = try await apiClient.mergeTopics(ids, targetId)
                    await send(.internal(.mergeTopicsResponse(.success(topicId))))
                } catch: { error, send in
                    await send(.internal(.mergeTopicsResponse(.failure(error))))
                }
                
            case let .internal(.mergeTopicsResponse(.success(topicId))):
                if topicId != 0 {
                    return .send(.delegate(.openTopic(topicId)))
                }
                return .send(.internal(.mergeTopicsResponse(.failure(NSError(domain: "MergeTopics", code: -1)))))
                
            case let .internal(.mergeTopicsResponse(.failure(error))):
                print(error)
                return .merge(
                    .run { _ in await dismiss() },
                    .run { _ in
                        let toast = ToastMessage(text: Localization.errorMergingTopics, isError: true)
                        await toastClient.showToast(toast)
                    }
                )
                
            case .delegate, .binding:
                return .none
            }
        }
    }
}
