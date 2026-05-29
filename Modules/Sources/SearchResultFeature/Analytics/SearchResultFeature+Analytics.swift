//
//  SearchResultFeature+Analytics.swift
//  ForPDA
//
//  Created by Codex on 10.05.2026.
//

import ComposableArchitecture
import AnalyticsClient

extension SearchResultFeature {
    
    struct Analytics: Reducer {
        typealias State = SearchResultFeature.State
        typealias Action = SearchResultFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onFirstAppear), .delegate:
                    break
                    
                case .pageNavigation(.offsetChanged(to: _)):
                    analytics.addBreadcrumb(
                        category: "SearchResultPageNavigation",
                        message: nil,
                        data: [
                            "page": state.pageNavigation.page
                        ],
                        type: "ui"
                    )
                    
                case .pageNavigation:
                    break
                    
                case let .view(.postTapped(topicId, postId)):
                    analytics.log(SearchResultEvent.postTapped(topicId, postId))
                    
                case let .view(.topicTapped(id, isUnreadTapped)):
                    analytics.log(SearchResultEvent.topicTapped(id, isUnreadTapped))
                    
                case let .view(.articleTapped(article)):
                    analytics.log(SearchResultEvent.articleTapped(article.id))
                    
                case .internal(.buildContent(_)),
                        .internal(.loadContent(offset: _)),
                        .internal(.searchResponse(_)),
                        .internal(.initUserSessionInfo):
                    break
                }
                
                return .none
            }
        }
    }
}
