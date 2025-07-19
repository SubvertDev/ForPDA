//
//  FavoriteRootFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import ComposableArchitecture
import AnalyticsClient

extension FavoritesRootFeature {
    
    struct Analytics: Reducer {
        typealias State = FavoritesRootFeature.State
        typealias Action = FavoritesRootFeature.Action
        
        @Dependency(\.analyticsClient) var analytics

        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.settingsButtonTapped):
                    analytics.log(FavoritesRootEvent.settingsButtonTapped)
                case .binding(\.pickerSelection):
                    analytics.log(FavoritesRootEvent.tabChanged(state.pickerSelection.rawValue))
                case .binding, .favorites, .bookmarks, .delegate:
                    break
                }
                return .none
            }
        }
    }
}
