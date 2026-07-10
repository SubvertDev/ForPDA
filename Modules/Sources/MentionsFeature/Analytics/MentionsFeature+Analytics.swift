//
//  MentionsFeature+Analytics.swift
//  ForPDA
//
//  Created by Codex on 10.05.2026.
//

import ComposableArchitecture
import AnalyticsClient

extension MentionsFeature {
    
    struct Analytics: Reducer {
        typealias State = MentionsFeature.State
        typealias Action = MentionsFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onAppear), .delegate:
                    break
                    
                case .pageNavigation(.offsetChanged(to: _)):
                    analytics.addBreadcrumb(
                        category: "MentionsPageNavigation",
                        message: nil,
                        data: [
                            "page": state.pageNavigation.page
                        ],
                        type: "ui"
                    )
                    
                case .pageNavigation:
                    break
                    
                case let .view(.mentionTapped(mention)):
                    analytics.log(
                        MentionsEvent.mentionTapped(
                            sourceId: mention.sourceId,
                            targetId: mention.targetId,
                            sourceName: mention.sourceName,
                            type: String(mention.type.rawValue)
                        )
                    )
                    
                case .internal(.loadMentions(offset: _)),
                        .internal(.mentionsResponse(_)):
                    break
                }
                
                return .none
            }
        }
    }
}
