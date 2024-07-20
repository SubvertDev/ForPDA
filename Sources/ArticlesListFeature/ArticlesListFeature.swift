//
//  ArticlesListFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import Models
import APIClient
import AnalyticsClient
import PasteboardClient

@Reducer
public struct ArticlesListFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var articles: [ArticlePreview]
        public var isLoading: Bool
        public var showShareSheet: Bool
        public var showVpnWarningBackground: Bool
        
        var loadAmount: Int = 30
        var offset: Int = 0
        
        public init(
            alert: AlertState<Action.Alert>? = nil,
            articles: [ArticlePreview] = [],
            isLoading: Bool = true,
            showShareSheet: Bool = false,
            showVpnWarningBackground: Bool = false
        ) {
            self.alert = alert
            self.articles = articles
            self.isLoading = isLoading
            self.showShareSheet = showShareSheet
            self.showVpnWarningBackground = showVpnWarningBackground
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case articleTapped(ArticlePreview)
        case binding(BindingAction<State>)
        case cellMenuOpened(ArticlePreview, ArticlesListRowMenuAction) // RELEASE: Should it be a delegate?
        case menuTapped
        case onFirstAppear
        case onRefresh
        case onLoadMoreAppear
        
        case _failedToConnect(any Error)
        case _articlesResponse(Result<[ArticlePreview], any Error>)
        
        case alert(PresentationAction<Alert>)
        public enum Alert {
            case cancel
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.pasteboardClient) var pasteboardClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
                // MARK: External
            case .articleTapped, .binding, .menuTapped:
                return .none
                
            case .cellMenuOpened(let article, let action):
                switch action {
                case .copyLink:  pasteboardClient.copy(url: article.url)
                case .shareLink: state.showShareSheet = true
                case .report:    break
                }
                return .none
                
            case .onFirstAppear:
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    do {
                        await apiClient.setLogResponses(type: .short)
                        try await apiClient.connect()
                        let result = await Result { try await apiClient.getArticlesList(offset: offset, amount: amount) }
                        await send(._articlesResponse(result))
                    } catch {
                        await send(._failedToConnect(error))
                    }
                }
                
            case .onRefresh:
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    // TODO: Better way to hold for 1 sec?
                    let startTime = DispatchTime.now()
                    let result = await Result { try await apiClient.getArticlesList(offset: offset, amount: amount) }
                    let endTime = DispatchTime.now()
                    let timeInterval = Int(Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds))
                    try await Task.sleep(for: .nanoseconds(1_000_000_000 - timeInterval))
                    await send(._articlesResponse(result))
                }
                
            case .onLoadMoreAppear:
                state.offset += state.loadAmount
                return .run { [offset = state.offset, amount = state.loadAmount] send in
                    let result = await Result {
                        try await apiClient.getArticlesList(offset: offset, amount: amount)
                    }
                    await send(._articlesResponse(result))
                }

                // MARK: Internal
                
            case ._failedToConnect:
                state.alert = .failedToConnect
                return .none
                
            case let ._articlesResponse(.success(articles)):
                state.isLoading = false
                if state.offset == 0 {
                    state.articles = articles
                } else {
                    state.articles.append(contentsOf: articles)
                }
                state.offset += state.loadAmount
                return .none
                
            case ._articlesResponse(.failure):
                state.isLoading = false
                state.alert = .failedToConnect
                return .none
                
                // MARK: Alert
                
            case .alert:
                state.alert = nil
                state.showVpnWarningBackground = true
                return .none
            }
        }
        
        Analytics()
    }
}

// MARK: - Alert Extension

extension AlertState where Action == ArticlesListFeature.Action.Alert {
    
    nonisolated(unsafe) static let failedToConnect = Self {
        TextState("Whoops!")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("OK")
        }
    } message: {
        TextState("Something went wrong while trying to connect to 4pda server...\nPlease try again later!")
    }
}
