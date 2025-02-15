//
//  CommentFeature+Analytics.swift
//
//
//  Created by Ilia Lubianoi on 05.07.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension CommentFeature {
    
    struct Analytics: Reducer {
        typealias State = CommentFeature.State
        typealias Action = CommentFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .onTask, ._timerTicked, ._likeResult, .alert:
                    break
                    
                case .profileTapped:
                    analytics.log(CommentEvent.profileTapped)
                    
                case .hiddenLabelTapped:
                    analytics.log(CommentEvent.hiddenLabelTapped)
                    
                case .reportButtonTapped:
                    analytics.log(CommentEvent.reportButtonTapped)
                    
                case .hideButtonTapped:
                    analytics.log(CommentEvent.hideButtonTapped)
                    
                case .replyButtonTapped:
                    analytics.log(CommentEvent.replyButtonTapped)
                    
                case .likeButtonTapped:
                    analytics.log(CommentEvent.likeButtonTapped)
                }
                
                return .none
            }
        }
    }
}

