//
//  FavoritesFeature.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import Foundation
import ComposableArchitecture
import PageNavigationFeature
import APIClient
import Models
import TCAExtensions
import PasteboardClient
import NotificationCenterClient

@Reducer
public struct FavoritesFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Presents var sort: SortFeature.State?
        
        public var favorites: [FavoriteInfo] = []
        public var favoritesImportant: [FavoriteInfo] = []
        
        public var isLoading = false
        public var isRefreshing = false
        public var unreadTapId: Int?
        
        public var pageNavigation = PageNavigationFeature.State(type: .forum)
        
        public init(
            favorites: [FavoriteInfo] = [],
            favoritesImportant: [FavoriteInfo] = []
        ) {
            self.favorites = favorites
            self.favoritesImportant = favoritesImportant
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onAppear
        case onRefresh
        case onSceneBecomeActive
        
        case settingsButtonTapped
        case favoriteTapped(id: Int, name: String, offset: Int, postId: Int?, isForum: Bool)
        case unreadTapped(id: Int)
        
        case contextOptionMenu(FavoritesOptionContextMenuAction)
        case commonContextMenu(FavoriteContextMenuAction, Bool)
        case topicContextMenu(FavoriteTopicContextMenuAction, Int)
        
        case pageNavigation(PageNavigationFeature.Action)
        
        case sort(PresentationAction<SortFeature.Action>)
        
        case _favoritesResponse(Result<[FavoriteInfo], any Error>)
        case _loadFavorites(offset: Int)
        case _startUnreadLoadingIndicator(id: Int)
        case _jumpRequestFailed
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    @Dependency(\.notificationCenter) private var notificationCenter
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Cancellable
    
    enum CancelID {
        case loading
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                guard state.favorites.isEmpty && state.favoritesImportant.isEmpty else { return .none }
                return .merge([
                    .send(._loadFavorites(offset: 0)),
                    .run { send in
                        for await _ in notificationCenter.observe(.favoritesUpdated) {
                            await send(._loadFavorites(offset: 0))
                        }
                    }
                ])
                
            case .onRefresh:
                state.isRefreshing = true
                state.unreadTapId = nil
                return .run { [offset = state.pageNavigation.offset] send in
                    await send(._loadFavorites(offset: offset))
                }
                
            case .onSceneBecomeActive:
                if state.isLoading {
                    return .none
                } else {
                    return .send(.onRefresh)
                }
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(._loadFavorites(offset: newOffset))
                
            case .sort(.presented(.saveButtonTapped)):
                return .run { send in
                    await send(.onRefresh)
                    await send(.sort(.presented(.cancelButtonTapped)))
                }
                
            case .sort(.presented(.cancelButtonTapped)):
                state.sort = nil
                return .none
                
            case .pageNavigation:
                return .none
                
            case .settingsButtonTapped, .sort:
                return .none
                
            case .favoriteTapped:
                return .cancel(id: CancelID.loading)
                
            case .contextOptionMenu(let action):
                switch action {
                case .sort:
                    state.sort = SortFeature.State()
                    return .none
                    
                case .markAllAsRead:
                    return .run { send in
                        _ = try await apiClient.readAllFavorites()
                        // TODO: Display toast on success/error.
                        
                        await send(.onRefresh)
                    }
                }
                
            case .commonContextMenu(let action, let isForum):
                switch action {
                case .copyLink(let id):
                    let show = isForum ? "showforum" : "showtopic"
                    pasteboardClient.copy(string: "https://4pda.to/forum/index.php?\(show)=\(id)")
                    return .none
                    
                case .delete(let id):
                    return .run { [id = id] send in
                        let request = SetFavoriteRequest(id: id, action: .delete, type: isForum ? .forum : .topic)
                        _ = try await apiClient.setFavorite(request)
                        // TODO: Display toast on success/error.
                        
                        await send(.onRefresh)
                    }
                    
                case .setImportant(let id, let pin):
                    return .run { [id = id] send in
                        let request = SetFavoriteRequest(id: id, action: pin ? .pin : .unpin, type: isForum ? .forum : .topic)
                        _ = try await apiClient.setFavorite(request)
                        // TODO: Display toast on success/error.
                        
                        await send(.onRefresh)
                    }
                }
                
            case .topicContextMenu(let action, let id):
                switch action {
                case .goToEnd:
                    return goToEnd(id: id)

                case .notifyHatUpdate(let flag):
                    return .run { [id = id, flag = flag] send in
                        await send(.topicContextMenu(.notify(flag, .hatUpdate), id))
                    }
                    
                case .notify(let flag, let notify):
                    return .run { [id = id, flag = flag, type = notify] send in
                        let request = NotifyFavoriteRequest(id: id, flag: flag, type: type)
                        _ = try await apiClient.notifyFavorite(request)
                        // TODO: Display toast on success/error.
                        
                        await send(.onRefresh)
                    }
                }
                
            case let .unreadTapped(id: id):
                return goToEnd(id: id)
                
            case let ._loadFavorites(offset):
                if !state.isRefreshing {
                    state.isLoading = true
                }
                return .run { [
                    perPage = state.appSettings.forumPerPage,
                    favoritesSettings = state.appSettings.favorites,
                    isRefreshing = state.isRefreshing
                ] send in
                    let startTime = Date()
                    for try await favorites in try await apiClient.getFavorites(
                        FavoritesRequest(
                            offset: offset,
                            perPage: perPage,
                            isSortByName: favoritesSettings.isSortByName,
                            isSortReverse: favoritesSettings.isReverseOrder,
                            isUnreadFirst: favoritesSettings.isUnreadFirst
                        ),
                        isRefreshing ? .cacheAndLoad : .cacheAndLoad
                    ) {
                        if isRefreshing { await delayUntilTimePassed(1.0, since: startTime) }
                        await send(._favoritesResponse(.success(favorites)))
                    }
                } catch: { error, send in
                    await send(._favoritesResponse(.failure(error)))
                }
                
            case let ._favoritesResponse(.success(response)):
                var favsImportant: [FavoriteInfo] = []
                var favorites: [FavoriteInfo] = []

                for favorite in response {
                    if favorite.isImportant {
                        favsImportant.append(favorite)
                    } else {
                        favorites.append(favorite)
                    }
                }
                
                state.favoritesImportant = favsImportant
                state.favorites = favorites
                
                // TODO: Is it ok?
                state.pageNavigation.count = response.count
                
                state.isLoading = false
                state.isRefreshing = false
                
                return .none
                
            case let ._favoritesResponse(.failure(error)):
                print("FAVORITES RESPONSE FAILURE: \(error)")
                return .none
                
            case let ._startUnreadLoadingIndicator(id: id):
                state.unreadTapId = id
                return .none
                
            case ._jumpRequestFailed:
                // Being watched in AppFeature to show toast
                state.unreadTapId = nil
                return .cancel(id: CancelID.loading)
            }
        }
        .ifLet(\.$sort, action: \.sort) {
            SortFeature()
        }
    }
    
    private func goToEnd(id: Int) -> Effect<Action> {
        return .merge(
            .run { send in
                try await clock.sleep(for: .seconds(1))
                await send(._startUnreadLoadingIndicator(id: id))
            }
            .cancellable(id: CancelID.loading, cancelInFlight: true),
            
            .run { send in
                let request = JumpForumRequest(postId: 0, topicId: id, allPosts: true, type: .new)
                let response = try await apiClient.jumpForum(request)
                    
                // TODO: Refactor
                await send(.onRefresh)
                await send(.favoriteTapped(id: id, name: "", offset: response.offset, postId: response.postId, isForum: false))
            } catch: { error, send in
                await send(._jumpRequestFailed)
            }
        )
    }
}
