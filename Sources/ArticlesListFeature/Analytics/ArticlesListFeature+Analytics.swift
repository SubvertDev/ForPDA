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
                case .menuTapped:
                    analyticsClient.log(ArticlesListEvent.menuTapped)
                    
                case .articleTapped(let article):
                    analyticsClient.log(ArticlesListEvent.articleTapped(article.id))
                    
                case .cellMenuOpened(let article, let action):
                    switch action {
                    case .copyLink:
                        analyticsClient.log(ArticlesListEvent.linkCopied(article.url))
                    case .shareLink:
                        analyticsClient.log(ArticlesListEvent.linkShared(article.url))
                    case .report:
                        analyticsClient.log(ArticlesListEvent.linkReported(article.url))
                        analyticsClient.capture(AnalyticsError.brokenArticle(article.url))
                    }
                    
                case .onFirstAppear:
                    break // TODO: Make First App Open/App Session here?
                    
                case .onRefresh:
                    analyticsClient.log(ArticlesListEvent.refreshTriggered)
                    
                case .onLoadMoreAppear:
                    analyticsClient.log(ArticlesListEvent.loadMoreTriggered)
                    
                case ._articlesResponse(.success):
                    analyticsClient.log(ArticlesListEvent.articlesHasLoaded)
                
                case ._articlesResponse(.failure(let error)):
                    analyticsClient.log(ArticlesListEvent.articlesHasNotLoaded(error.localizedDescription))
                    analyticsClient.capture(AnalyticsError.apiFailure(error))
                    
                case .binding, .alert, ._articlesResponse:
                    break
                    
                case ._failedToConnect(let error):
                    print(error)
                    analyticsClient.log(ArticlesListEvent.failedToConnect)
                    analyticsClient.capture(error)
                }
                return .none
            }
        }
    }
}
