//
//  ArticlesListFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import TCAExtensions
import Models
import APIClient
import AnalyticsClient
import PasteboardClient

@Reducer
public struct ArticlesListFeature: Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination: Hashable {
        @ReducerCaseIgnored
        case share(URL)
        case alert(AlertState<Never>)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        public var articles: [ArticlePreview]
        public var isLoading: Bool
        public var loadAmount: Int = 15
        public var offset: Int = 0
        public var listGridTypeShort = false
        
        public var isScrollDisabled: Bool {
            // Disables scroll until first load
            return articles.isEmpty && isLoading
        }
        
        public var scrollToTop: Bool = false
        
        public init(
            destination: Destination.State? = nil,
            articles: [ArticlePreview] = [],
            isLoading: Bool = true,
            listGridTypeShort: Bool = false
        ) {
            self.destination = destination
            self.articles = articles
            self.isLoading = isLoading
            self.listGridTypeShort = listGridTypeShort
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case destination(PresentationAction<Destination.Action>)
        case articleTapped(ArticlePreview)
        case binding(BindingAction<State>) // TODO: Remove
        case cellMenuOpened(ArticlePreview, ArticlesListRowMenuAction) // TODO: Should it be a delegate?
        case linkShared(Bool, URL)
        case listGridTypeButtonTapped
        case settingsButtonTapped
        case onFirstAppear
        case onRefresh
        case scrolledToNearEnd
        
        case _failedToConnect(any Error)
        case _articlesResponse(Result<[ArticlePreview], any Error>)
        case _loadMoreArticles
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
                // MARK: External
            case .articleTapped, .binding, .destination:
                return .none
                
            case .cellMenuOpened(let article, let action):
                switch action {
                case .shareLink:      state.destination = .share(article.url)
                case .copyLink:       pasteboardClient.copy(string: article.url.absoluteString)
                case .openInBrowser:  return .run { _ in await open(url: article.url) }
                case .report:         break
                case .addToBookmarks: break
                }
                return .none
                
            case .linkShared:
                state.destination = nil
                return .none
                
            case .onFirstAppear:
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    do {
                        await apiClient.setLogResponses(type: .none)
                        try await apiClient.connect()
                        let result = await Result { try await apiClient.getArticlesList(offset: offset, amount: amount) }
                        await send(._articlesResponse(result))
                    } catch {
                        await send(._failedToConnect(error))
                    }
                }
                
            case .onRefresh:
                state.offset = 0
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    // TODO: Better way to hold for 1 sec?
                    let startTime = DispatchTime.now()
                    let result = await Result { try await apiClient.getArticlesList(offset: offset, amount: amount) }
                    let endTime = DispatchTime.now()
                    let timeInterval = Int(Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds))
                    try await Task.sleep(for: .nanoseconds(1_000_000_000 - timeInterval))
                    await send(._articlesResponse(result))
                }
                
            case .listGridTypeButtonTapped:
                state.listGridTypeShort.toggle()
                return .none
                
            case .settingsButtonTapped:
                return .none
                
            case .scrolledToNearEnd:
                guard !state.isLoading else { return .none }
                guard state.articles.count != 0 else { return .none }
                return .run { send in
                    await send(._loadMoreArticles)
                }
                
                // MARK: Internal
                
            case ._loadMoreArticles:
                state.isLoading = true
                state.offset += state.loadAmount
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    let result = await Result {
                        try await apiClient.getArticlesList(offset: offset, amount: amount)
                    }
                    await send(._articlesResponse(result))
                }
                
            case ._failedToConnect:
                state.destination = .alert(.failedToConnect)
                return .none
                
            case let ._articlesResponse(.success(articles)):
                if state.offset == 0 {
                    state.articles = articles
                } else {
                    state.articles.append(contentsOf: articles)
                }
                state.offset += state.loadAmount
                state.isLoading = false
                return .none
                
            case ._articlesResponse(.failure):
                state.isLoading = false
                state.destination = .alert(.failedToConnect)
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Analytics()
    }
}
