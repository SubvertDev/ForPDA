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
                case .onAppear:
                    break
                    
                case .onRefresh:
                    analytics.log(FavoritesEvent.onRefresh)
                    
                case .onSceneBecomeActive:
                    analytics.log(FavoritesEvent.onSceneBecomeActive)
                    
                case let .favoriteTapped(id: id, name: name, offset: _, postId: postId, isForum: isForum):
                    analytics.log(FavoritesEvent.favoriteTapped(id, name, postId, isForum))
                    
                case let .unreadTapped(id: id):
                    analytics.log(FavoritesEvent.unreadTapped(id))
                    
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
                    
                case let .topicContextMenu(option, id):
                    switch option {
                    case .goToEnd:
                        analytics.log(FavoritesEvent.goToEnd(id))
                    case let .notify(flag, notify):
                        analytics.log(FavoritesEvent.notify(id, flag, notify.rawValue))
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
                    
                case let ._startUnreadLoadingIndicator(id: id):
                    analytics.log(FavoritesEvent.startUnreadLoadingIndicator(id))
                    
                case ._jumpRequestFailed:
                    analytics.log(FavoritesEvent.jumpRequestFailed)
                }
                
                return .none
            }
        }
    }
}
