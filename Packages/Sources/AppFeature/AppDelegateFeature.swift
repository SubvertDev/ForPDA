//
//  AppDelegateFeature.swift
//
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient
import CacheClient

@Reducer
public struct AppDelegateFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    public struct State: Equatable {
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        case didFinishLaunching
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didFinishLaunching:
                analyticsClient.configure()
                cacheClient.configure()
                return .none
            }
        }
    }
}
