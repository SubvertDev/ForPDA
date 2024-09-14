//
//  ArticlesListFeature+Analytics.swift
//
//
//  Created by Ilia Lubianoi on 19.05.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension ArticlesListFeature {
    
    struct Analytics: Reducer {
        typealias State = ArticlesListFeature.State
        typealias Action = ArticlesListFeature.Action
        
        @Dependency(\.analyticsClient) var analyticsClient
        
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .articleTapped(let article):
                    analyticsClient.log(ArticlesListEvent.articleTapped(article.id))
                    
                case .cellMenuOpened(let article, let action):
                    switch action {
                    case .shareLink:
                        analyticsClient.log(ArticlesListEvent.linkShareOpened(article.url))
                    case .copyLink:
                        analyticsClient.log(ArticlesListEvent.linkCopied(article.url))
                    case .openInBrowser:
                        analyticsClient.log(ArticlesListEvent.articleOpenedInBrowser(article.url))
                    case .report:
                        analyticsClient.log(ArticlesListEvent.linkReported(article.url))
                        analyticsClient.capture(AnalyticsError.brokenArticle(article.url))
                    case .addToBookmarks:
                        analyticsClient.log(ArticlesListEvent.articleAddedToBookmarks(article.url))
                    }
                    
                case let .linkShared(success, url):
                    analyticsClient.log(ArticlesListEvent.linkShared(success, url))
                    
                case .listGridTypeButtonTapped:
                    analyticsClient.log(ArticlesListEvent.listGridTypeChanged(state.listGridTypeShort))
                    
                case .settingsButtonTapped:
                    analyticsClient.log(ArticlesListEvent.settingsButtonTapped)
                    
                case .onFirstAppear:
                    break // TODO: Make First App Open/App Session here?
                    
                case .onRefresh:
                    analyticsClient.log(ArticlesListEvent.refreshTriggered)
                    
                case ._articlesResponse(.success):
                    analyticsClient.log(ArticlesListEvent.articlesHasLoaded)
                
                case ._articlesResponse(.failure(let error)):
                    analyticsClient.log(ArticlesListEvent.articlesHasNotLoaded(error.localizedDescription))
                    analyticsClient.capture(AnalyticsError.apiFailure(error))
                    
                case ._loadMoreArticles:
                    analyticsClient.log(ArticlesListEvent.loadMoreTriggered)
                    
                case .binding, .scrolledToNearEnd, ._articlesResponse, .destination:
                    break
                    
                case ._failedToConnect(let error):
                    analyticsClient.log(ArticlesListEvent.failedToConnect)
                    analyticsClient.capture(error)
                }
                return .none
            }
        }
    }
}
