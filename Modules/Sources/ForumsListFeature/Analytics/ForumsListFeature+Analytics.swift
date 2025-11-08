//
//  ForumsListFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import ComposableArchitecture
import AnalyticsClient

extension ForumsListFeature {
    
    struct Analytics: Reducer {
        typealias State = ForumsListFeature.State
        typealias Action = ForumsListFeature.Action
        
        @Dependency(\.analyticsClient) var analytics

        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onAppear):
                    break
                    
                case let .view(.forumRedirectTapped(url)):
                    analytics.log(ForumsListEvent.forumRedirectTapped(url))
                    
                case let .view(.forumTapped(id: id, name: name)):
                    analytics.log(ForumsListEvent.forumTapped(id, name))
                    
                case let .view(.forumSectionExpandTapped(id)):
                    analytics.log(ForumsListEvent.forumSectionExpanded(id))
                    
                case let .internal(.forumsListResponse(response)):
                    switch response {
                    case .success:
                        analytics.log(ForumsListEvent.forumListLoadSuccess)
                    case let .failure(error):
                        analytics.log(ForumsListEvent.forumListLoadFailure(error))
                    }
                    
                case .delegate:
                    break
                }
                
                return .none
            }
        }
    }
}
