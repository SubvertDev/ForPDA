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
import HapticClient
import PersistenceKeys

@Reducer
public struct ArticlesListFeature: Reducer, Sendable {
    
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
        @Shared(.appSettings) public var appSettings: AppSettings
        public var articles: [ArticlePreview]
        public var isLoading: Bool
        public var loadAmount: Int
        public var offset: Int
        public var listRowType: AppSettings.ArticleListRowType = .normal
        
        public var isScrollDisabled: Bool {
            // Disables scroll until first load
            return articles.isEmpty && isLoading
        }
        
        public var scrollToTop: Bool = false
        
        public init(
            destination: Destination.State? = nil,
            appSettings: AppSettings = .default,
            articles: [ArticlePreview] = [],
            isLoading: Bool = true,
            loadAmount: Int = 15,
            offset: Int = 0
        ) {
            self.destination = destination
            self._appSettings = Shared(wrappedValue: appSettings, .appSettings)
            self.articles = articles
            self.isLoading = isLoading
            self.loadAmount = loadAmount
            self.offset = offset
            
            self.listRowType = $appSettings.articlesListRowType.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        case destination(PresentationAction<Destination.Action>)
        case articleTapped(ArticlePreview)
        case binding(BindingAction<State>)
        case cellMenuOpened(ArticlePreview, ContextMenuOptions)
        case linkShared(Bool, URL)
        case listGridTypeButtonTapped
        case settingsButtonTapped
        case onRefresh
        case loadMoreArticles
        
        case _articlesResponse(Result<[ArticlePreview], any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    @Dependency(\.hapticClient) private var hapticClient
    @Dependency(\.continuousClock) private var clock
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
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
                case .addToBookmarks:
                    state.destination = .alert(.notImplemented)
                    return .run { _ in await hapticClient.play(.rigid) }
                }
                return .none
                
            case .linkShared:
                state.destination = nil
                return .none
                
            case .onAppear:
                guard state.articles.isEmpty else { return .none }
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    let result = await Result { try await apiClient.getArticlesList(offset: offset, amount: amount) }
                    await send(._articlesResponse(result))
                }
                
            case .onRefresh:
                state.offset = 0
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    // TODO: Better way to hold for 1 sec?
                    let startTime = DispatchTime.now()
                    let result = await Result { try await apiClient.getArticlesList(offset: offset, amount: amount) }
                    let endTime = DispatchTime.now()
                    let timeInterval = Int(Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds))
                    try await clock.sleep(for: .nanoseconds(1_000_000_000 - timeInterval))
                    await send(._articlesResponse(result))
                }
                
            case .listGridTypeButtonTapped:
                state.listRowType = AppSettings.ArticleListRowType.toggle(from: state.listRowType)
                return .run { [appSettings = state.$appSettings, listRowType = state.listRowType] _ in
                    await hapticClient.play(.selection)
                    await appSettings.withLock { $0.articlesListRowType = listRowType }
                }
                
            case .settingsButtonTapped:
                return .none
                
                // MARK: Internal
                
            case .loadMoreArticles:
                guard !state.isLoading else { return .none }
                guard state.articles.count != 0 else { return .none }
                state.isLoading = true
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    let result = await Result {
                        try await apiClient.getArticlesList(offset: offset, amount: amount)
                    }
                    await send(._articlesResponse(result))
                }
                
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
