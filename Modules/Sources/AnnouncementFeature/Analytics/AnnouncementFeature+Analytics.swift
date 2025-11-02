//
//  AnnouncementFeature+Analytics.swift
//  
//
//  Created by Ilia Lubianoi on 05.07.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension AnnouncementFeature {
    
    struct Analytics: Reducer {
        typealias State = AnnouncementFeature.State
        typealias Action = AnnouncementFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onAppear),
                        .view(.urlTapped):
                    break
                    
                case .internal(.announcementResponse),
                        .internal(.loadAnnouncement),
                        .internal(.loadTypes):
                    break
                    
                case .delegate(.handleUrl):
                    break
                }
                
                return .none
            }
        }
    }
}

