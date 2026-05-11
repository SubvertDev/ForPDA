//
//  DeviceSpecificationsFeature+Analytics.swift
//  ForPDA
//
//  Created by Codex on 11.05.2026.
//

import ComposableArchitecture
import AnalyticsClient

extension DeviceSpecificationsFeature {
    
    struct Analytics: Reducer {
        typealias State = DeviceSpecificationsFeature.State
        typealias Action = DeviceSpecificationsFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onAppear), .internal, .delegate, .destination, .binding:
                    break
                    
                case .view(.contextMenu(.copyLink)):
                    let subTag = state.subTag.map { ":\($0)" } ?? ""
                    let url = "https://4pda.to/devdb/\(state.tag)\(subTag)"
                    analytics.log(DeviceSpecificationsEvent.linkCopied(url))
                    
                case let .view(.headerImageTapped(id)):
                    analytics.log(DeviceSpecificationsEvent.headerImageTapped(id))
                    
                case let .view(.editionButtonTapped(subTag)):
                    analytics.log(DeviceSpecificationsEvent.editionTapped(subTag))
                    
                case let .view(.markAsMyDeviceButtonTapped(isMyDevice)):
                    analytics.log(DeviceSpecificationsEvent.markAsMyDeviceTapped(isMyDevice))
                    
                case let .view(.longEntryButtonTapped(entry)):
                    analytics.log(DeviceSpecificationsEvent.longEntryTapped(entry.name))
                    
                case .view(.longEntryCloseButtonTapped):
                    analytics.log(DeviceSpecificationsEvent.longEntryCloseTapped)
                }
                
                return .none
            }
        }
    }
}
