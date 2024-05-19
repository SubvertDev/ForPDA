//
//  AppDelegateFeature.swift
//
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import ComposableArchitecture
import AnalyticsClient
import ImageClient
import CookiesClient

@Reducer
public struct AppDelegateFeature {
    
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
    
    @Dependency(\.analyticsClient) var analyticsClient
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.cookiesClient) var cookiesClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didFinishLaunching:
                analyticsClient.configure() // RELEASE: Check
                imageClient.configure()
                cookiesClient.configure()
                
                return .none
            }
        }
    }
}
