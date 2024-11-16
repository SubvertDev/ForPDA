//
//  BookmarksFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import Foundation
import ComposableArchitecture
import TCAExtensions
import APIClient
import PasteboardClient
import Models
import PersistenceKeys

@Reducer
public struct BookmarksFeature: Reducer, Sendable {
    
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
        public var isLoading: Bool = false
        public var listRowType: AppSettings.ArticleListRowType = .normal
        public var articles: [ArticlePreview] = []
        public var scrollToTop: Bool = false
        
        public var isScrollDisabled: Bool {
            // Disables scroll until first load
            return articles.isEmpty && isLoading
        }
        
        public init(
            destination: Destination.State? = nil
        ) {
            self.listRowType = $appSettings.articlesListRowType.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case destination(PresentationAction<Destination.Action>)
        case binding(BindingAction<State>) // TODO: Remove

        case onTask
        case onRefresh
        case listGridTypeButtonTapped
        case settingsButtonTapped
        case linkShared(Bool, URL)
        case articleTapped(ArticlePreview)
        case cellMenuOpened(ArticlePreview, ContextMenuOptions)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onTask:
                return .none
                
            case .onRefresh:
                return .none
                
            case .listGridTypeButtonTapped:
                state.listRowType = AppSettings.ArticleListRowType.toggle(from: state.listRowType)
                return .run { [appSettings = state.$appSettings, listRowType = state.listRowType] _ in
                    await appSettings.withLock { $0.articlesListRowType = listRowType }
                }
                
            case .settingsButtonTapped:
                return .none
                
            case .linkShared:
                state.destination = nil
                return .none
                
            case .articleTapped:
                return .none
                
            case let .cellMenuOpened(article, options):
                switch options {
                case .shareLink:      state.destination = .share(article.url)
                case .copyLink:       pasteboardClient.copy(string: article.url.absoluteString)
                case .openInBrowser:  return .run { _ in await open(url: article.url) }
                case .report:         break
                case .addToBookmarks: break
                }
                return .none
                
            case .destination, .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        // TODO: Analytics
    }
}
