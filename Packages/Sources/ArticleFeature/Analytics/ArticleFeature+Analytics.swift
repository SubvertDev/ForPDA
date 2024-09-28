//
//  ArticleFeature+Analytics.swift
//  
//
//  Created by Ilia Lubianoi on 05.07.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension ArticleFeature {
    
    struct Analytics: Reducer {
        typealias State = ArticleFeature.State
        typealias Action = ArticleFeature.Action
        
        @Dependency(\.analyticsClient) var analyticsClient
        
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    // TODO: Catch all
                case .binding, .delegate, ._checkLoading, .destination, .backButtonTapped, .comments, .notImplementedButtonTapped, .sendCommentButtonTapped, .removeReplyCommentButtonTapped, ._commentResponse:
                    break
                    
                case .linkInTextTapped(let url):
                    analyticsClient.log(ArticleEvent.inlineLinkTapped(url))
                    
                case .menuActionTapped(let action):
                    switch action {
                    case .copyLink:
                        analyticsClient.log(ArticleEvent.linkCopied(state.articlePreview.url))
                    case .shareLink:
                        analyticsClient.log(ArticleEvent.linkShareOpened(state.articlePreview.url))
                    case .report:
                        analyticsClient.log(ArticleEvent.linkReported(state.articlePreview.url))
                        analyticsClient.capture(AnalyticsError.brokenArticle(state.articlePreview.url))
                    }
                    
                case let .linkShared(success, url):
                    analyticsClient.log(ArticleEvent.linkShared(success, url))
                    
                case .onTask:
                    break // TODO: Log?
                    
                case .bookmarkButtonTapped:
                    analyticsClient.log(ArticleEvent.bookmarkButtonTapped(state.articlePreview.url))
                    
                case ._articleResponse(.success):
                    analyticsClient.log(ArticleEvent.loadingSuccess)
                    
                case ._articleResponse(.failure(let error)):
                    analyticsClient.log(ArticleEvent.loadingFailure(error))
                    analyticsClient.capture(error)
                    
                case ._parseArticleElements(.success):
                    break
                    
                case ._parseArticleElements(.failure(let error)):
                    analyticsClient.log(ArticleEvent.loadingFailure(error))
                    analyticsClient.capture(error)
                }
                
                return .none
            }
        }
    }
}

