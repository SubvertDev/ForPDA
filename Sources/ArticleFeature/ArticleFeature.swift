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
import CacheClient
import PasteboardClient

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
        @Presents public var destination: Destination.State?
        public var articlePreview: ArticlePreview
        public var article: Article?
        public var elements: [ArticleElement]?
        public var isLoading: Bool
        
        public init(
            destination: Destination.State? = nil,
            articlePreview: ArticlePreview,
            article: Article? = nil,
            isLoading: Bool = false
        ) {
            self.destination = destination
            self.articlePreview = articlePreview
            self.article = article
            self.isLoading = isLoading
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case destination(PresentationAction<Destination.Action>)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case linkInTextTapped(URL)
        case menuActionTapped(ArticleMenuAction)
        case linkShared(Bool, URL)
        case onTask
        
        case _checkLoading
        case _articleResponse(Result<Article, any Error>)
        case _parseArticleElements(Result<[ArticleElement], any Error>)
        
        @CasePathable
        public enum Delegate {
            case handleDeeplink(Int)
            case commentHeaderTapped(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.cacheClient) var cacheClient
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
//                
//            case .alert:
//                state.alert = nil
//                return .run { _ in await self.dismiss() }
            }
        }
        .ifLet(\.$destination, action: \.destination)

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
        TextState("Whoops!")
    } actions: {
        ButtonState(role: .cancel, action: .ok) {
            TextState("OK")
        }
    } message: {
        TextState("Something went wrong while loading this article :(")
    }
}
