//
//  ArticleFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import Models
import APIClient
import PasteboardClient

@Reducer
public struct ArticleFeature: Sendable {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var articlePreview: ArticlePreview
        public var article: Article?
        public var elements: [ArticleElement]?
        public var isLoading: Bool
        public var showShareSheet: Bool
        @Presents public var alert: AlertState<Action.Alert>?
        
        public init(
            articlePreview: ArticlePreview,
            article: Article? = nil,
            isLoading: Bool = false,
            showShareSheet: Bool = false,
            alert: AlertState<Action.Alert>? = nil
        ) {
            self.articlePreview = articlePreview
            self.article = article
            self.isLoading = isLoading
            self.showShareSheet = showShareSheet
            self.alert = alert
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case linkInTextTapped(URL)
        case menuActionTapped(ArticleMenuAction)
        case onTask
        
        case _checkLoading
        case _articleResponse(Result<Article, any Error>)
        case _parseArticleElements(Result<[ArticleElement], any Error>)
        
        case alert(PresentationAction<Alert>)
        public enum Alert {
            case cancel
        }
        
        @CasePathable
        public enum Delegate {
            case handleDeeplink(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.parsingClient) var parsingClient
    @Dependency(\.pasteboardClient) var pasteboardClient
    @Dependency(\.openURL) var openURL
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Cancellable
    
    enum CancelID {
        case loading
    }
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none
                
            case let .linkInTextTapped(url):
                return .run { send in
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                        if let host = components.host,
                           host.contains("4pda") {
                            // TODO: Already has one in AppFeature, make DeeplinkHandler?
                            let regex = #//([\d]{6})//#
                            let match = url.absoluteString.firstMatch(of: regex)
                            let id = Int(match!.output.1)!
                            await send(.delegate(.handleDeeplink(id)))
                            return
                        }
                    }
                    await openURL(url)
                }
                
            case let .menuActionTapped(action):
                switch action {
                case .copyLink:  pasteboardClient.copy(url: state.articlePreview.url)
                case .shareLink: state.showShareSheet = true
                case .report:    break
                }
                return .none
                
            case .onTask:
                return .merge([
                    loadingIndicator(),
                    getArticle(id: state.articlePreview.id)
                ])
                
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
                
                return .run { send in
                    let result = await Result { try await parsingClient.parseArticleElements(article) }
                    await send(._parseArticleElements(result))
                }
                
            case ._articleResponse(.failure):
                state.isLoading = false
                state.alert = .error
                return .none
                
            case ._parseArticleElements(.success(let elements)):
                state.elements = elements
                state.isLoading = false
                return .none
                
            case ._parseArticleElements(.failure):
                state.isLoading = false
                state.alert = .error
                return .none
                
            case .alert:
                state.alert = nil
                return .run { _ in await self.dismiss() }
            }
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
                let result = await Result { try await apiClient.getArticle(id: id) }
                await send(._articleResponse(result))
            },
            .cancel(id: CancelID.loading)
        ])
    }
}

// MARK: - Alert Extension

public extension AlertState where Action == ArticleFeature.Action.Alert {
    nonisolated(unsafe) static let error = Self {
        TextState("Whoops!")
    } actions: {
        ButtonState(role: .cancel, action: .cancel) {
            TextState("OK")
        }
    } message: {
        TextState("Something went wrong while loading this article :(")
    }
}
