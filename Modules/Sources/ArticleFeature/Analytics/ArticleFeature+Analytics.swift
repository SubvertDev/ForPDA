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
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .binding,
                        .comments,
                        .delegate,
                        .destination,
                        .notImplementedButtonTapped,
                        .onTask,
                        ._checkLoading,
                        ._commentResponse,
                        ._pollVoteResponse,
                        ._stopRefreshingIfFinished:
                    break
                    
                case .backButtonTapped:
                    analytics.log(ArticleEvent.backButtonTapped)
                    
                case .pollVoteButtonTapped:
                    analytics.log(ArticleEvent.pollVoteTapped)
                    
                case .removeReplyCommentButtonTapped:
                    analytics.log(ArticleEvent.removeReplyCommentTapped)
                    
                case .sendCommentButtonTapped:
                    analytics.log(ArticleEvent.sendCommentTapped)
                    
                case .linkInTextTapped(let url):
                    analytics.log(ArticleEvent.inlineLinkTapped(url))
                    
                case .menuActionTapped(let action):
                    switch action {
                    case .copyLink:
                        analytics.log(ArticleEvent.linkCopied(state.articlePreview.url))
                    case .shareLink:
                        analytics.log(ArticleEvent.linkShareOpened(state.articlePreview.url))
                    case .report:
                        analytics.log(ArticleEvent.linkReported(state.articlePreview.url))
                    }
                    
                case let .linkShared(success, url):
                    analytics.log(ArticleEvent.linkShared(success, url))
                    
                case .onRefresh:
                    analytics.log(ArticleEvent.onRefresh)
                    
                case .bookmarkButtonTapped:
                    analytics.log(ArticleEvent.bookmarkButtonTapped(state.articlePreview.url))
                    
                case ._articleResponse(.success):
                    // Send only first success event (skip cached opening)
                    if state.article == nil {
                        analytics.log(ArticleEvent.loadingSuccess)
                    }
                    
                case ._articleResponse(.failure(let error)):
                    analytics.log(ArticleEvent.loadingFailure(error))
                    analytics.capture(error)
                    
                case ._parseArticleElements(.success):
                    break
                    
                case ._parseArticleElements(.failure(let error)):
                    analytics.log(ArticleEvent.loadingFailure(error))
                    analytics.capture(error)
                }
                
                return .none
            }
        }
    }
}

