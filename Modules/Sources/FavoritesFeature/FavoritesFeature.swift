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
import AnalyticsClient
import ToastClient

@Reducer
public struct FavoritesFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        @Presents var sort: SortFeature.State?
        
        public var favorites: [FavoriteInfo] = []
        public var favoritesImportant: [FavoriteInfo] = []
        
        public var isLoading = true
        public var isRefreshing = false
        public var shouldShowEmptyState: Bool {
            return !isLoading && favorites.isEmpty && favoritesImportant.isEmpty
        }
        
        public var pageNavigation = PageNavigationFeature.State(type: .forum)
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        var didLoadOnce = false
        
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
        
        case favoriteTapped(FavoriteInfo)
        case unreadTapped(FavoriteInfo)
        
        case contextOptionMenu(FavoritesOptionContextMenuAction)
        case commonContextMenu(FavoriteContextMenuAction, Bool)
        case topicContextMenu(FavoriteTopicContextMenuAction, FavoriteInfo)
        
        case pageNavigation(PageNavigationFeature.Action)
        
        case sort(PresentationAction<SortFeature.Action>)
        
        case _favoritesResponse(Result<Favorite, any Error>)
        case _loadFavorites(offset: Int)
        case _jumpRequestFailed
        
        case delegate(Delegate)
        public enum Delegate {
            case openForum(id: Int, name: String)
//            case openTopic(id: Int, name: String, offset: Int, postId: Int?)
            case openTopic(id: Int, name: String, goTo: GoTo)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    @Dependency(\.notificationCenter) private var notificationCenter
    @Dependency(\.continuousClock) private var clock
    
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
                    updatePageNavigation(&state, offset: 0),
                    .send(._loadFavorites(offset: 0)),
                    .run { send in
                        for await _ in notificationCenter.observe(.favoritesUpdated) {
                            await send(._loadFavorites(offset: 0))
                        }
                    }
                ])
                
            case .onRefresh:
                guard !state.isLoading else { return .none }
                state.isRefreshing = true
                return .concatenate(
                    .cancel(id: CancelID.loading),
                    .run { [offset = state.pageNavigation.offset] send in
                        await send(._loadFavorites(offset: offset))
                    }
                )
                
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
                
            case .sort:
                return .none
                
            case let .favoriteTapped(favorite):
                return .concatenate(
                    .cancel(id: CancelID.loading),
                    .run { send in
                        if favorite.isForum {
                            await send(.delegate(.openForum(id: favorite.topic.id, name: favorite.topic.name)))
                        } else {
                            await send(.delegate(.openTopic(id: favorite.topic.id, name: favorite.topic.name, goTo: .first)))
//                            await send(.delegate(.openTopic(id: favorite.topic.id, name: favorite.topic.name, offset: 0, postId: nil)))
                        }
                    }
                )
                
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
                    pasteboardClient.copy("https://4pda.to/forum/index.php?\(show)=\(id)")
                    return .none
                    
                case .delete(let id):
                    return .run { send in
                        let request = SetFavoriteRequest(id: id, action: .delete, type: isForum ? .forum : .topic)
                        _ = try await apiClient.setFavorite(request)
                        // TODO: Display toast on success/error.
                        
                        await send(.onRefresh)
                    }
                    
                case .setImportant(let id, let pin):
                    return .run { send in
                        let request = SetFavoriteRequest(id: id, action: pin ? .pin : .unpin, type: isForum ? .forum : .topic)
                        _ = try await apiClient.setFavorite(request)
                        // TODO: Display toast on success/error.
                        
                        await send(.onRefresh)
                    }
                }
                
            case let .topicContextMenu(action, favorite):
                switch action {
                case .goToEnd:
                    return .send(.delegate(.openTopic(id: favorite.topic.id, name: favorite.topic.name, goTo: .last)))

                case .notifyHatUpdate(let flag):
                    return .run { send in
                        await send(.topicContextMenu(.notify(flag, .hatUpdate), favorite))
                    }
                    
                case .notify(let flag, let notify):
                    return .run { send in
                        let request = NotifyFavoriteRequest(id: favorite.topic.id, flag: flag, type: notify)
                        _ = try await apiClient.notifyFavorite(request)
                        // TODO: Display toast on success/error.
                        
                        await send(.onRefresh)
                    }
                }
                
            case let .unreadTapped(favorite):
                return goToUnread(favorite: favorite)
                
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

                for favorite in response.favorites {
                    if favorite.isImportant {
                        favsImportant.append(favorite)
                    } else {
                        favorites.append(favorite)
                    }
                }
                                
                state.favoritesImportant = favsImportant
                state.favorites = favorites
                
                state.isLoading = false
                state.isRefreshing = false
                
                reportFullyDisplayed(&state)
                
                return updatePageNavigation(&state, count: response.favoritesCount)
                
            case let ._favoritesResponse(.failure(error)):
                print("FAVORITES RESPONSE FAILURE: \(error)")
                reportFullyDisplayed(&state)
                return showToast(.whoopsSomethingWentWrong)
                
            case ._jumpRequestFailed:
                return .merge(
                    .cancel(id: CancelID.loading),
                    showToast(.postNotFound)
                )
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$sort, action: \.sort) {
            SortFeature()
        }
        
        Analytics()
    }
    
    // MARK: - Shared logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
    
    private func updatePageNavigation(_ state: inout State, count: Int = 0, offset: Int? = nil) -> Effect<Action> {
        return PageNavigationFeature()
            .reduce(
                into: &state.pageNavigation,
                action: .update(
                    count: count,
                    offset: offset
                )
            )
            .map(Action.pageNavigation)
    }
    
    private func goToUnread(favorite: FavoriteInfo) -> Effect<Action> {
        return .concatenate(
            .send(.delegate(.openTopic(id: favorite.topic.id, name: favorite.topic.name, goTo: .unread))),
            .send(.onRefresh)
        )
//        return .merge(
//            .run { send in
//                try await clock.sleep(for: .seconds(1))
//                await send(._startUnreadLoadingIndicator(id: favorite.topic.id))
//            }
//            .cancellable(id: CancelID.loading, cancelInFlight: true),
//            
//            .run { send in
//                let id = favorite.topic.id
//                let request = JumpForumRequest(postId: 0, topicId: id, allPosts: true, type: .new)
//                let response = try await apiClient.jumpForum(request)
//                    
//                // TODO: Refactor
//                await send(.onRefresh)
//                await send(.delegate(.openTopic(id: id, name: favorite.topic.name, offset: response.offset, postId: response.postId)))
//            } catch: { error, send in
//                await send(._jumpRequestFailed)
//            }
//        )
    }
    
    private func showToast(_ toast: ToastMessage) -> Effect<Action> {
        return .run { _ in
            await toastClient.showToast(toast)
        }
    }
}
