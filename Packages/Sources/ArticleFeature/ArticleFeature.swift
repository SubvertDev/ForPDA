//
//  ArticleFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import TCAExtensions
import Models
import APIClient
import CacheClient
import PasteboardClient
import HapticClient

@Reducer
public struct ArticleFeature: Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination: Hashable {
        @ReducerCaseIgnored
        case share(URL)
        case alert(AlertState<Alert>)
        
        public enum Alert { case ok }
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field: Sendable { case comment }

        @Presents public var destination: Destination.State?
        public var articlePreview: ArticlePreview
        public var article: Article?
        public var elements: [ArticleElement]?
        public var isLoading: Bool
        public var comments: IdentifiedArrayOf<CommentFeature.State>
        public var replyComment: Comment?
        public var commentText: String
        public var isUploadingComment: Bool
        public var focus: Field?
        
        public init(
            destination: Destination.State? = nil,
            articlePreview: ArticlePreview,
            article: Article? = nil,
            isLoading: Bool = false,
            comments: IdentifiedArrayOf<CommentFeature.State> = [],
            replyComment: Comment? = nil,
            commentText: String = "",
            isUploadingComment: Bool = false,
            focus: Field? = nil
        ) {
            self.destination = destination
            self.articlePreview = articlePreview
            self.article = article
            self.isLoading = isLoading
            self.comments = comments
            self.replyComment = replyComment
            self.commentText = commentText
            self.isUploadingComment = isUploadingComment
            self.focus = focus
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case destination(PresentationAction<Destination.Action>)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case backButtonTapped
        case bookmarkButtonTapped
        case notImplementedButtonTapped
        case menuActionTapped(ArticleMenuAction)
        case linkShared(Bool, URL)
        case linkInTextTapped(URL)
        case onTask
        case comments(IdentifiedActionOf<CommentFeature>)
        case sendCommentButtonTapped
        case removeReplyCommentButtonTapped
        
        case _checkLoading
        case _articleResponse(Result<Article, any Error>)
        case _commentResponse(Result<CommentResponseType, any Error>)
        case _parseArticleElements(Result<[ArticleElement], any Error>)
        
        @CasePathable
        public enum Delegate {
            case handleDeeplink(Int)
            case commentHeaderTapped(Int)
            case showToast(CommentResponseType)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.cacheClient) var cacheClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.parsingClient) var parsingClient
    @Dependency(\.pasteboardClient) var pasteboardClient
    @Dependency(\.openURL) var openURL
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Cancellable
    
    enum CancelID {
        case loading
    }
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case let .comments(.element(id, action)):
                if case .replyButtonTapped = action {
                    if let comment = state.comments[id: id]?.comment {
                        state.focus = .comment
                        state.replyComment = comment
                    }
                }
                return .none
                
            case .comments:
                return .none
                
            case .binding, .delegate, .destination:
                return .none
                
            case let .linkInTextTapped(url):
                return .run { send in
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                        if let host = components.host,
                           host.contains("4pda") {
                            // TODO: Already has one in AppFeature, make DeeplinkHandler?
                            let regex = #//([\d]{6})//#
                            let match = url.absoluteString.firstMatch(of: regex)
                            if let match, let id = Int(match.output.1) {
                                await send(.delegate(.handleDeeplink(id)))
                                return
                            }
                            // TODO: Redirect case fallthrough
                        }
                    }
                    await openURL(url)
                }
                
            case let .menuActionTapped(action):
                switch action {
                case .copyLink:  pasteboardClient.copy(string: state.articlePreview.url.absoluteString)
                case .shareLink: state.destination = .share(state.articlePreview.url)
                case .report:    break
                }
                return .none
                
            case .linkShared:
                state.destination = nil
                return .none
                
            case .onTask:
                guard state.article == nil else { return .none }
                return .merge([
                    loadingIndicator(),
                    getArticle(id: state.articlePreview.id)
                ])
                
            case .backButtonTapped:
                return .run { _ in await dismiss() }
                
            case .bookmarkButtonTapped:
                state.destination = .alert(.notImplemented)
                return .none
                
            case .notImplementedButtonTapped:
                state.destination = .alert(.notImplemented)
                return .none
                
            case .sendCommentButtonTapped:
                state.isUploadingComment = true
                return .run { [articleId = state.articlePreview.id,
                               replyComment = state.replyComment,
                               message = state.commentText] send in
                    let parentId: Int
                    if let replyComment {
                        parentId = replyComment.id
                    } else {
                        parentId = 0
                    }
                    
                    let result = await Result { try await apiClient.replyToComment(articleId, parentId, message) }
                    await send(._commentResponse(result))
                }
                
            case .removeReplyCommentButtonTapped:
                state.replyComment = nil
                return .none
                
            case ._checkLoading:
                if state.article == nil {
                    state.isLoading = true
                }
                return .none
                
            case ._articleResponse(.success(let article)):
                // Outer && inner deeplink case
                if state.articlePreview.date.timeIntervalSince1970 == 0 || state.articlePreview.title.isEmpty {
                    state.articlePreview = ArticlePreview.makeFromArticle(article)
                }
                
                state.article = article
                
                for comment in article.comments {
                    let commentFeature = CommentFeature.State(comment: comment, articleId: state.articlePreview.id)
                    // TODO: Does equality check helps with performance?
                    state.comments[id: comment.id] = commentFeature
                }
                
                // TODO: Cache parsing result and move into cache check
                return .run { send in
                    let result = await Result { try await parsingClient.parseArticleElements(article) }
                    await send(._parseArticleElements(result))
                }
                
            case ._articleResponse(.failure):
                state.isLoading = false
                state.destination = .alert(.error)
                return .none
                
            case let ._commentResponse(.success(type)):
                state.isUploadingComment = false
                if type.isError {
                    state.focus = nil
                    return .run { send in
                        await hapticClient.play(.error)
                        await send(.delegate(.showToast(type)))
                    }
                } else {
                    state.commentText.removeAll()
                    state.replyComment = nil
                    state.focus = nil
                    return .concatenate([
                        getArticle(id: state.articlePreview.id),
                        .run { send in
                            await hapticClient.play(.success)
                            await send(.delegate(.showToast(type)))
                        }
                    ])
                }
                
            case let ._commentResponse(.failure(error)):
                print(error) // TODO: Catch to Issue
                state.isUploadingComment = false
                state.destination = .alert(.error)
                return .none
                
            case ._parseArticleElements(.success(let elements)):
                state.elements = elements
                state.isLoading = false
                return .run { _ in
                    var urls: [URL] = []
                    for case let .image(image) in elements {
                        urls.append(image.url)
                    }
                    await cacheClient.preloadImages(urls)
                }
                
            case ._parseArticleElements(.failure):
                state.isLoading = false
                state.destination = .alert(.error)
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.comments, action: \.comments) {
            CommentFeature()
        }

        Analytics()
    }
    
    // MARK: - Effects
    
    private func loadingIndicator() -> EffectOf<Self> {
        return .run { send in
            try await clock.sleep(for: .seconds(0.5))
            await send(._checkLoading)
        }
        .cancellable(id: CancelID.loading)
    }
    
    private func getArticle(id: Int) -> EffectOf<Self> {
        return .concatenate([
            .run { send in
                do {
                    for try await article in try await apiClient.getArticle(id: id) {
                        await send(._articleResponse(.success(article)))
                    }
                } catch {
                    await send(._articleResponse(.failure(error)))
                }
            },
            .cancel(id: CancelID.loading)
        ])
    }
}

// MARK: - Alert Extension

public extension AlertState where Action == ArticleFeature.Destination.Alert {
    nonisolated(unsafe) static let error = Self {
        TextState("Whoops!", bundle: .module)
    } actions: {
        ButtonState(role: .cancel, action: .ok) {
            TextState("OK")
        }
    } message: {
        TextState("Something went wrong while loading this article :(", bundle: .module)
    }
}
