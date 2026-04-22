//
//  ForumMoveFeature.swift
//  ForPDA
//
//  Created by Xialtal on 11.04.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import DeeplinkHandler
import ToastClient

@Reducer
public struct ForumMoveFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localization
    
    private enum Localization {
        static let errorMovingTopic = LocalizedStringResource("Error moving topic", bundle: .module)
        static let errorMovingPosts = LocalizedStringResource("Error moving posts", bundle: .module)
    }
    
    // MARK: - URL Validation Error Reason
    
    public enum URLValidationErrorReason {
        case badURL
        case needTopicUrl
        case needForumUrl
        case unableToExtractTopicId
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field { case url }
        
        public let type: ForumMoveType
        
        var focus: Field? = .url
        var error: URLValidationErrorReason?
        var isSending = false
        
        var inputUrl = ""
        var isSaveLinkForTopic = false
        
        var isMoveButtonDisabled: Bool {
            return error != nil || inputUrl.isEmpty
        }
        
        public init(
            type: ForumMoveType
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
            
            case unlockMoveButton
            
            case moveButtonTapped
            case cancelButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case movePosts([Int], toTopicid: Int)
            case moveTopic(Int, toForumid: Int)
            
            case movePostsResponse(Result<(Bool, Int), any Error>)
            case moveTopicResponse(Result<(Bool, Int), any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openDeeplink(Deeplink)
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
                return .none
                
            case .view(.unlockMoveButton):
                state.error = nil
                return .none
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.moveButtonTapped):
                if let url = URL(string: state.inputUrl.trimmingCharacters(in: .whitespacesAndNewlines)),
                   let artefact = try? DeeplinkHandler().handleInnerToInnerURL(url) {
                    switch artefact {
                    case .topic(let topicId, _):
                        guard case .posts(let ids) = state.type else {
                            state.error = .needForumUrl
                            break
                        }
                        guard let topicId = topicId else {
                            state.error = .unableToExtractTopicId
                            break
                        }
                        return .send(.internal(.movePosts(ids, toTopicid: topicId)))
                        
                    case .forum(let forumId, _):
                        guard case .topic(let topicId) = state.type else {
                            state.error = .needTopicUrl
                            break
                        }
                        return .send(.internal(.moveTopic(topicId, toForumid: forumId)))
                        
                    default:
                        state.error = .badURL
                    }
                } else {
                    state.error = .badURL
                }
                return .none
                
            case let .internal(.movePosts(ids, toTopicId)):
                state.isSending = true
                return .run { send in
                    let status = try await apiClient.movePosts(ids: ids, toTopicId: toTopicId)
                    await send(.internal(.movePostsResponse(.success((status, toTopicId: toTopicId)))))
                } catch: { error, send in
                    await send(.internal(.movePostsResponse(.failure(error))))
                }
                
            case let .internal(.moveTopic(topicId, toForumId)):
                state.isSending = true
                return .run { [saveLink = state.isSaveLinkForTopic] send in
                    let status = try await apiClient.moveTopic(
                        id: topicId,
                        toForumId: toForumId,
                        saveLink: saveLink
                    )
                    await send(.internal(.moveTopicResponse(.success((status, toForumId: toForumId)))))
                } catch: { error, send in
                    await send(.internal(.moveTopicResponse(.failure(error))))
                }
                
            case let .internal(.movePostsResponse(.success((status, toTopicId)))):
                if status {
                    return .send(.delegate(.openDeeplink(.topic(id: toTopicId, goTo: .last))))
                }
                return .send(.internal(.movePostsResponse(.failure(NSError(domain: "MP", code: -1)))))
                
            case let .internal(.movePostsResponse(.failure(error))):
                print(error)
                return .merge(
                    .run { _ in await dismiss() },
                    .run { _ in
                        let toast = ToastMessage(text: Localization.errorMovingPosts, isError: true)
                        await toastClient.showToast(toast)
                    }
                )
                
            case let .internal(.moveTopicResponse(.success((status, toForumId)))):
                if status {
                    return .send(.delegate(.openDeeplink(.forum(id: toForumId, page: 0))))
                }
                return .send(.internal(.moveTopicResponse(.failure(NSError(domain: "MT", code: -1)))))
                
            case let .internal(.moveTopicResponse(.failure(error))):
                print(error)
                return .merge(
                    .run { _ in await dismiss() },
                    .run { _ in
                        let toast = ToastMessage(text: Localization.errorMovingTopic, isError: true)
                        await toastClient.showToast(toast)
                    }
                )
                
            case .delegate, .binding:
                return .none
            }
        }
    }
}
