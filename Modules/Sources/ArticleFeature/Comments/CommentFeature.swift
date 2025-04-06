//
//  CommentFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.09.2024.
//

import Foundation
import ComposableArchitecture
import TCAExtensions
import PersistenceKeys
import APIClient
import Models

public enum CommentContextMenuOptions {
    case report
    case hide
}

@Reducer
public struct CommentFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, Identifiable {
        @Presents public var alert: AlertState<Never>?
        @Shared(.userSession) public var userSession: UserSession?
        public var id: Int { return comment.id }
        public var comment: Comment
        public let articleId: Int
        public let isArticleExpired: Bool
        public var isLiked: Bool
        
        public var isAuthorized: Bool {
            return userSession != nil
        }
        
        var dateUpdate = false
        
        init(
            alert: AlertState<Never>? = nil,
            comment: Comment,
            articleId: Int,
            isArticleExpired: Bool,
            isLiked: Bool = false
        ) {
            self.alert = alert
            self.comment = comment
            self.articleId = articleId
            self.isArticleExpired = isArticleExpired
            self.isLiked = isLiked
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case alert(PresentationAction<Never>)
        case profileTapped(userId: Int)
        case hiddenLabelTapped
        case reportButtonTapped
        case hideButtonTapped
        case replyButtonTapped
        case likeButtonTapped
        
        case _likeResult(Bool)
        case _timerTicked
        
        case delegate(Delegate)
        public enum Delegate {
            case commentHeaderTapped(Int)
            case unauthorizedAction
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.hapticClient) private var hapticClient
    @Dependency(\.continuousClock) private var clock
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onTask:
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(60)) {
                        await send(._timerTicked)
                    }
                }
                
            case ._timerTicked:
                state.dateUpdate.toggle()
                return .none
                
            case .alert:
                return .none
                
            case let .profileTapped(id):
                return .send(.delegate(.commentHeaderTapped(id)))
                
            case .hiddenLabelTapped:
                state.comment.isHidden = false
                return .none
                
            case .reportButtonTapped:
                guard state.isAuthorized else {
                    return .send(.delegate(.unauthorizedAction))
                }
                state.alert = .notImplemented
                return .none
                
            case .hideButtonTapped:
                guard state.isAuthorized else {
                    return .send(.delegate(.unauthorizedAction))
                }
                state.comment.isHidden.toggle()
                return .run { [articleId = state.articleId, commentId = state.comment.id] _ in
                    await hapticClient.play(.selection)
                    let _ = try await apiClient.hideComment(articleId: articleId, commentId: commentId)
                }
                
            case .replyButtonTapped:
                guard state.isAuthorized else {
                    return .send(.delegate(.unauthorizedAction))
                }
                return .none
                
            case .likeButtonTapped:
                guard !state.isLiked else { return .none }
                guard state.isAuthorized else {
                    return .send(.delegate(.unauthorizedAction))
                }
                state.comment.likesAmount += 1
                state.isLiked = true
                return .run { [articleId = state.articleId, commentId = state.comment.id] send in
                    let success = try await apiClient.likeComment(articleId: articleId, commentId: commentId)
                    await send(._likeResult(success))
                }
                
            case let ._likeResult(success):
                if success {
                    // TODO: Show toast
                } else {
                    // state.comment.likesAmount -= 1
                }
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.alert, action: \.alert)
    }
}
