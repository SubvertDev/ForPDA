//
//  FavoriteFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import ComposableArchitecture
import AnalyticsClient

extension FavoritesFeature {
    
    struct Analytics: Reducer {
        typealias State = FavoritesFeature.State
        typealias Action = FavoritesFeature.Action
        
        @Dependency(\.analyticsClient) var analytics

        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .onAppear, .delegate:
                    break
                    
                case .onRefresh:
                    analytics.log(FavoritesEvent.onRefresh)
                    
                case .onSceneBecomeActive:
                    analytics.log(FavoritesEvent.onSceneBecomeActive)
                    
                case let .favoriteTapped(favorite):
                    analytics.log(FavoritesEvent.favoriteTapped(favorite.topic.id, favorite.topic.name, nil, favorite.isForum))
                    
                case let .unreadTapped(favorite):
                    analytics.log(FavoritesEvent.unreadTapped(favorite.topic.id))
                    
                case let .contextOptionMenu(option):
                    switch option {
                    case .sort:
                        analytics.log(FavoritesEvent.sortButtonTapped)
                    case .markAllAsRead:
                        analytics.log(FavoritesEvent.readAllButtonTapped)
                    }
                    
                case let .commonContextMenu(option, isForum):
                    switch option {
                    case let .setImportant(id, pinned):
                        analytics.log(FavoritesEvent.setImportant(id, pinned))
                    case let .copyLink(id):
                        analytics.log(FavoritesEvent.linkCopied(id, isForum))
                    case let .delete(id):
                        analytics.log(FavoritesEvent.delete(id))
                    }
                    
                case let .topicContextMenu(option, favorite):
                    switch option {
                    case .goToEnd:
                        analytics.log(FavoritesEvent.goToEnd(favorite.topic.id))
                    case let .notify(flag, notify):
                        analytics.log(FavoritesEvent.notify(favorite.topic.id, flag, notify.rawValue))
                    case let .notifyHatUpdate(flag):
                        analytics.log(FavoritesEvent.notifyHatUpdate(flag))
                    }
                    
                case .pageNavigation:
                    break // Handled inside navigation
                    
                case .sort(.dismiss):
                    analytics.log(FavoritesEvent.sortDismissed)
                    
                case let .sort(.presented(action)):
                    switch action {
                    case .onAppear, .binding:
                        break
                    case let .didSelectSortType(type):
                        analytics.log(FavoritesEvent.sortTypeSelected(type.title))
                    case .saveButtonTapped:
                        analytics.log(FavoritesEvent.sortSaveButtonTapped)
                    case .cancelButtonTapped:
                        analytics.log(FavoritesEvent.sortCancelButtonTapped)
                    }
                    
                case let ._favoritesResponse(response):
                    switch response {
                    case .success:
                        analytics.log(FavoritesEvent.loadingSuccess)
                    case let .failure(error):
                        analytics.log(FavoritesEvent.loadingFailure(error))
                    }
                    
                case let ._loadFavorites(offset: offset):
                    analytics.log(FavoritesEvent.loadingStart(offset))
                    
                case ._jumpRequestFailed:
                    analytics.log(FavoritesEvent.jumpRequestFailed)
                }
                
                return .none
            }
        }
    }
}
