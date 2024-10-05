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
public struct CommentFeature: Sendable {
    
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
        case alert(PresentationAction<Never>)
        case profileTapped(userId: Int)
        case hiddenLabelTapped
        case reportButtonTapped
        case hideButtonTapped
        case replyButtonTapped
        case likeButtonTapped
        
        case _likeResult(Bool)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.hapticClient) private var hapticClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
                
            case .profileTapped:
                return .none
                
            case .hiddenLabelTapped:
                state.comment.isHidden = false
                return .none
                
            case .reportButtonTapped:
                guard state.isAuthorized else { return .none }
                state.alert = .notImplemented
                return .none
                
            case .hideButtonTapped:
                guard state.isAuthorized else { return .none }
                state.comment.isHidden.toggle()
                return .run { [articleId = state.articleId, commentId = state.comment.id] _ in
                    await hapticClient.play(.selection)
                    let _ = try await apiClient.hideComment(articleId: articleId, commentId: commentId)
                }
                
            case .replyButtonTapped:
                return .none
                
            case .likeButtonTapped:
                guard !state.isLiked else { return .none }
                guard state.isAuthorized else { return .none }
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
            }
        }
        .ifLet(\.alert, action: \.alert)
    }
}
