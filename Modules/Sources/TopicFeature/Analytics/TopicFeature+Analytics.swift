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
                case .onAppear, .onSceneBecomeActive, .pageNavigation, .writeForm, ._loadTypes, ._goToPost, ._jumpRequestFailed, .finishedPostAnimation, ._load, .delegate:
                    break
                    
                case .onRefresh:
                    analytics.log(TopicEvent.onRefresh)
                    
                case let .userAvatarTapped(userId: userId):
                    analytics.log(TopicEvent.userAvatarTapped(userId))
                    
                case let .urlTapped(url):
                    analytics.log(TopicEvent.urlTapped(url))
                    
                case let .contextPostMenu(option):
                    switch option {
                    case .reply(let userId, _):
                        analytics.log(TopicEvent.menuPostReply(userId))
                    case .edit(let post):
                        analytics.log(TopicEvent.menuPostEdit(post.id))
                    case .delete(let postId):
                        analytics.log(TopicEvent.menuPostDelete(postId))
                    }
                    
                case let .contextMenu(option):
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
                    }
                    
                case let ._loadTopic(offset: offset):
                    analytics.log(TopicEvent.loadingStart(offset))
                    
                case let ._topicResponse(response):
                    switch response {
                    case .success:
                        analytics.log(TopicEvent.loadingSuccess)
                    case let .failure(error):
                        analytics.log(TopicEvent.loadingFailure(error))
                    }
                    
                case let ._setFavoriteResponse(response):
                    analytics.log(TopicEvent.setFavoriteResponse(response))
                }
                
                return .none
            }
        }
    }
}
