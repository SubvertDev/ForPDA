//
//  DeviceTypeFeature+Analytics.swift
//  ForPDA
//
//  Created by Xialtal on 13.04.2026.
//

import ComposableArchitecture
import AnalyticsClient

extension DeviceTypeFeature {
    
    struct Analytics: Reducer {
        typealias State = DeviceTypeFeature.State
        typealias Action = DeviceTypeFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.deviceButtonTapped(let tag)):
                    analytics.log(DeviceTypeEvent.deviceTapped(tag))
                    
                case .view(.typeButtonTapped(let type)):
                    analytics.log(DeviceTypeEvent.typeTapped(type.rawValue))
                    
                case .view(.vendorButtonTapped(let name, let type)):
                    analytics.log(DeviceTypeEvent.vendorTapped(name, type: type.rawValue))
                    
                case .delegate, .internal, .view:
                    break
                }
                return .none
            }
        }
    }
}
