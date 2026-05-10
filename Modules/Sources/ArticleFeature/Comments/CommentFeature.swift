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
import ToastClient
import ReputationChangeFeature
import FormFeature
import AuthFeature

public enum CommentContextMenuOptions {
    case report
    case hide
}

@Reducer
public struct CommentFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    public enum Localization {
        static let reportSent = LocalizedStringResource("Report sent", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        case changeReputation(ReputationChangeFeature)
        case report(FormFeature)
        case auth(AuthFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, Identifiable {
        @Presents public var alert: AlertState<Never>?
        @Presents var destination: Destination.State?
        @Shared(.userSession) public var userSession: UserSession?
        public var id: Int { return comment.id }
        public var comment: Comment
        public let articleId: Int
        public let isArticleExpired: Bool
        public let canComment: Bool
        public var isLiked: Bool
        
        public var isAuthorized: Bool {
            return userSession != nil
        }
        
        public var canReactToComment: Bool {
            return isAuthorized && comment.canReact
        }
        
        var dateUpdate = false
        
        init(
            alert: AlertState<Never>? = nil,
            comment: Comment,
            articleId: Int,
            isArticleExpired: Bool,
            isLiked: Bool = false,
            canComment: Bool
        ) {
            self.alert = alert
            self.comment = comment
            self.articleId = articleId
            self.isArticleExpired = isArticleExpired
            self.isLiked = isLiked
            self.canComment = canComment
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
        case changeReputationButtonTapped
        
        case destination(PresentationAction<Destination.Action>)
        
        case _likeResult(Bool)
        case _timerTicked
        
        case delegate(Delegate)
        public enum Delegate {
            case commentHeaderTapped(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.hapticClient) private var hapticClient
    @Dependency(\.toastClient) private var toastClient
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
                
            case .destination(.presented(.report(.delegate(.formSent(.report))))):
                return .run { _ in
                    await toastClient.showToast(ToastMessage(text: Localization.reportSent, haptic: .success))
                }
                
            case .hiddenLabelTapped:
                state.comment.isHidden = false
                return .none
                
            case .reportButtonTapped:
                guard state.isAuthorized else {
                    state.destination = .auth(AuthFeature.State())
                    return .none
                }
                
                state.destination = .report(
                    FormFeature.State(type: .report(id: state.comment.id, type: .comment))
                )
                return .none
                
            case .changeReputationButtonTapped:
                guard state.isAuthorized else {
                    state.destination = .auth(AuthFeature.State())
                    return .none
                }
                
                state.destination = .changeReputation(
                    ReputationChangeFeature.State(
                        userId: state.comment.authorId,
                        username: state.comment.authorName,
                        content: .comment(id: state.comment.id)
                    )
                )
                return .none
                
            case .hideButtonTapped:
                guard state.isAuthorized else {
                    state.destination = .auth(AuthFeature.State())
                    return .none
                }
                
                state.comment.isHidden.toggle()
                
                return .run { [articleId = state.articleId, commentId = state.comment.id] _ in
                    await hapticClient.play(.selection)
                    let _ = try await apiClient.hideComment(articleId: articleId, commentId: commentId)
                }
                
            case .replyButtonTapped:
                guard state.isAuthorized else {
                    state.destination = .auth(AuthFeature.State())
                    return .none
                }
                return .none
                
            case .likeButtonTapped:
                guard !state.isLiked else { return .none }
                guard state.isAuthorized else {
                    state.destination = .auth(AuthFeature.State())
                    return .none
                }
                
                state.comment.likesAmount += 1
                state.isLiked = true
                
                return .run { [articleId = state.articleId, commentId = state.comment.id] send in
                    let success = try await apiClient.likeComment(articleId: articleId, commentId: commentId)
                    await send(._likeResult(success))
                    await hapticClient.play(type: .selection)
                }
                
            case let ._likeResult(success):
                if success {
                    // TODO: Show toast
                } else {
                    // state.comment.likesAmount -= 1
                }
                return .none
                
            case .destination(.presented(.auth(.delegate(.loginSuccess(userId: _))))):
                state.destination = nil
                return .none
                
            case .delegate, .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Extensions

extension CommentFeature.Destination.State: Equatable {}
