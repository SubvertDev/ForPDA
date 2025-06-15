//
//  TopicFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import ComposableArchitecture
import AnalyticsClient

extension TopicFeature {
    
    struct Analytics: Reducer {
        typealias State = TopicFeature.State
        typealias Action = TopicFeature.Action
        
        @Dependency(\.analyticsClient) var analytics

        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onAppear),
                        .view(.onSceneBecomeActive),
                        .view(.finishedPostAnimation),
                        .internal(.loadTypes),
                        .internal(.goToPost),
                        .internal(.jumpRequestFailed),
                        .internal(.load),
                        .internal(.refresh),
                        .pageNavigation,
                        .destination,
                        .delegate,
                        .binding:
                    break
                    
                case .view(.onRefresh):
                    analytics.log(TopicEvent.onRefresh)
                    
                case .view(.topicHatOpenButtonTapped):
                    analytics.log(TopicEvent.topicHatOpenButtonTapped)
                    
                case let .view(.userTapped(userId: userId)):
                    analytics.log(TopicEvent.userTapped(userId))
                    
                case let .view(.urlTapped(url)):
                    analytics.log(TopicEvent.urlTapped(url))
                    
                case let .view(.imageTapped(url)):
                    analytics.log(TopicEvent.imageTapped(url))
                    
                case let .view(.contextPostMenu(option)):
                    switch option {
                    case .reply(let userId, _):
                        analytics.log(TopicEvent.menuPostReply(userId))
                    case .edit(let post):
                        analytics.log(TopicEvent.menuPostEdit(post.id))
                    case .delete(let postId):
                        analytics.log(TopicEvent.menuPostDelete(postId))
                    }
                    
                case let .view(.contextMenu(option)):
                    switch option {
                    case .copyLink:
                        analytics.log(TopicEvent.menuCopyLink)
                    case .openInBrowser:
                        analytics.log(TopicEvent.menuOpenInBrowser)
                    case .goToEnd:
                        analytics.log(TopicEvent.menuGoToEnd)
                    case .setFavorite:
                        analytics.log(TopicEvent.menuSetFavorite)
                    case .writePost:
                        analytics.log(TopicEvent.menuWritePost)
                    case .writePostWithTemplate:
                        analytics.log(TopicEvent.menuWritePostWithTemplate)
                    }
                    
                case .view(.editWarningSheetCloseButtonTapped):
                    analytics.log(TopicEvent.editWarningSheetClosed)
                    
                case let .internal(.loadTopic(offset: offset)):
                    analytics.log(TopicEvent.loadingStart(offset))
                    
                case let .internal(.topicResponse(response)):
                    switch response {
                    case .success:
                        analytics.log(TopicEvent.loadingSuccess)
                    case let .failure(error):
                        analytics.log(TopicEvent.loadingFailure(error))
                    }
                    
                case let .internal(.setFavoriteResponse(response)):
                    analytics.log(TopicEvent.setFavoriteResponse(response))
                }
                
                return .none
            }
        }
    }
}
