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
                case .view(.onFirstAppear),
                        .view(.onNextAppear),
                        .view(.finishedPostAnimation),
                        .view(.changeKarmaTapped),
                        .view(.topicPollVoteButtonTapped),
                        .view(.searchButtonTapped),
                        .internal(.loadTypes),
                        .internal(.goToPost),
                        .internal(.jumpRequestFailed),
                        .internal(.changeKarma),
                        .internal(.voteInPoll),
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
                    
                case .view(.topicPollOpenButtonTapped):
                    analytics.log(TopicEvent.topicPollOpenButtonTapped)
                    
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
                    case .karma(let postId):
                        analytics.log(TopicEvent.menuPostKarma(postId))
                    case .edit(let post):
                        analytics.log(TopicEvent.menuPostEdit(post.id))
                    case .report(let postId):
                        analytics.log(TopicEvent.menuPostReport(postId))
                    case .delete(let postId):
                        analytics.log(TopicEvent.menuPostDelete(postId))
                    case .changeReputation(let postId, let userId, _):
                        analytics.log(TopicEvent.menuChangeReputation(postId, userId))
                    case .postMentions(let postId):
                        analytics.log(TopicEvent.menuPostMentions(postId))
                    case .copyLink(let postId):
                        analytics.log(TopicEvent.menuPostCopyLink(postId))
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
                    }
                    
                case .view(.editWarningSheetCloseButtonTapped):
                    analytics.log(TopicEvent.editWarningSheetClosed)
                    
                case .internal(.loadTopic):
                    break
                    
                case .internal(.topicResponse):
                    break
                    
                case .internal(.setFavoriteResponse):
                    break
                }
                
                return .none
            }
        }
    }
}
