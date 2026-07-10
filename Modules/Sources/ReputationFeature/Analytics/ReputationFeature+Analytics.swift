//
//  ReputationFeature+Analytics.swift
//  ForPDA
//
//  Created by Codex on 10.05.2026.
//

import AnalyticsClient
import ComposableArchitecture

extension ReputationFeature {
    
    struct Analytics: Reducer {
        typealias State = ReputationFeature.State
        typealias Action = ReputationFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { _, action in
                switch action {
                case .view(.onAppear), .internal, .delegate, .destination:
                    break
                    
                case .binding(\.pickerSection):
                    analytics.log(ReputationEvent.pickerSectionChanged)
                    
                case .binding:
                    break
                    
                case .view(.loadMore):
                    analytics.log(ReputationEvent.loadMoreTapped)
                    
                case .view(.refresh):
                    analytics.log(ReputationEvent.refreshTapped)
                    
                case let .view(.profileTapped(profileId)):
                    analytics.log(ReputationEvent.profileTapped(profileId))
                    
                case let .view(.contextVoteMenu(action)):
                    switch action {
                    case .report(let voteId):
                        analytics.log(ReputationEvent.voteMenuComplainTapped(voteId))
                    case .goToAuthor(let profileId):
                        analytics.log(ReputationEvent.voteMenuGoToAuthorTapped(profileId))
                    case .modify:
                        // MARK: Moderator tools are skip analytics
                        break
                    }
                    
                case let .view(.sourceTapped(vote)):
                    switch vote.createdIn {
                    case .profile:
                        analytics.log(ReputationEvent.profileTapped(vote.authorId))
                    case let .topic(id: topicId, topicName: _, postId: _):
                        analytics.log(ReputationEvent.sourceTopicTapped(topicId))
                    case let .site(id: articleId, _, _):
                        analytics.log(ReputationEvent.sourceArticleTapped(articleId))
                    }
                }
                
                return .none
            }
        }
    }
}
