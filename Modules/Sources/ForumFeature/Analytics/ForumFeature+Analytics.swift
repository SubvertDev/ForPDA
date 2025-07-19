//
//  ForumFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import ComposableArchitecture
import AnalyticsClient

extension ForumFeature {
    
    struct Analytics: Reducer {
        typealias State = ForumFeature.State
        typealias Action = ForumFeature.Action
        
        @Dependency(\.analyticsClient) var analytics

        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .onAppear, .pageNavigation, .delegate:
                    break
                    
                case .onRefresh:
                    analytics.log(ForumEvent.onRefresh)
                    
                case let .topicTapped(topic, showUnread):
                    analytics.log(ForumEvent.topicTapped(topic.id, showUnread))
                    
                case let .subforumRedirectTapped(url):
                    analytics.log(ForumEvent.subforumRedirectTapped(url))
                    
                case let .subforumTapped(forum):
                    analytics.log(ForumEvent.subforumTapped(forum.id, forum.name))
                    
                case let .announcementTapped(id: id, name: name):
                    analytics.log(ForumEvent.announcementTapped(id, name))
                    
                case let .contextOptionMenu(option):
                    switch option {
                    case .sort:
                        break // TODO: Add
                    case .toBookmarks:
                        break // TODO: Add
                    }
                case let .contextTopicMenu(option, topic):
                    switch option {
                    case .open:
                        analytics.log(ForumEvent.menuOpen(topic.id))
                    case .goToEnd:
                        analytics.log(ForumEvent.menuGoToEnd(topic.id))
                    }
                case let .contextCommonMenu(option, id, isForum):
                    switch option {
                    case .markRead:
                        analytics.log(ForumEvent.menuMarkRead(id, isForum))
                    case .copyLink:
                        analytics.log(ForumEvent.menuCopyLink(id, isForum))
                    case .openInBrowser:
                        analytics.log(ForumEvent.menuOpenInBrowser(id, isForum))
                    case let .setFavorite(state):
                        analytics.log(ForumEvent.menuSetFavorite(id, isForum, state))
                    }
                    
                case let ._loadForum(offset: offset):
                    analytics.log(ForumEvent.loadingStart(offset))
                    
                case let ._forumResponse(response):
                    switch response {
                    case .success:
                        analytics.log(ForumEvent.loadingSuccess)
                    case let .failure(error):
                        analytics.log(ForumEvent.loadingFailure(error))
                    }
                }
                
                return .none
            }
        }
    }
}
