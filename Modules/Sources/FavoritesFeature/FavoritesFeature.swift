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
import AnalyticsClient
import ToastClient
import NotificationsClient

@Reducer
public struct FavoritesFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    public enum Localization {
        static let linkCopied = LocalizedStringResource("Link copied", bundle: .module)
        static let markAsReadSuccess = LocalizedStringResource("Marked as read", bundle: .module)
        static let notifyTypeChanged = LocalizedStringResource("Notify type changed", bundle: .module)
        static let sortFiltersChanged = LocalizedStringResource("Sort filters are changed", bundle: .module)
    }
    
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
            favoritesImportant: [FavoriteInfo] = [],
            sort: SortFeature.State? = nil
        ) {
            self.favorites = favorites
            self.favoritesImportant = favoritesImportant
            self.sort = sort
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case pageNavigation(PageNavigationFeature.Action)
        case sort(PresentationAction<SortFeature.Action>)
        
        case view(View)
        public enum View {
            case onFirstAppear
            case onNextAppear
            case onRefresh
            case onSceneBecomeActive
            case favoriteTapped(FavoriteInfo, showUnread: Bool)
            case contextOptionMenu(FavoritesOptionContextMenuAction)
            case commonContextMenu(FavoriteContextMenuAction, Bool)
            case topicContextMenu(FavoriteTopicContextMenuAction, FavoriteInfo)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case refresh
            case favoritesResponse(Result<Favorite, any Error>)
            case loadFavorites(offset: Int)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openForum(id: Int, name: String)
            case openTopic(id: Int, name: String, goTo: GoTo)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    @Dependency(\.notificationCenter) private var notificationCenter
    @Dependency(\.notificationsClient) private var notificationsClient
    @Dependency(\.continuousClock) private var clock
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(.internal(.loadFavorites(offset: newOffset)))
                
            case .sort(.presented(.saveButtonTapped)):
                return .concatenate(
                    .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.sortFiltersChanged, haptic: .success))
                    },
                    
                    .send(.internal(.refresh)),
                    .send(.sort(.presented(.cancelButtonTapped)))
                )
                
            case .sort(.presented(.cancelButtonTapped)):
                state.sort = nil
                return .none
                
            case .pageNavigation, .sort:
                return .none
                
            case .view(.onFirstAppear):
                return .merge([
                    updatePageNavigation(&state, offset: 0),
                    .send(.internal(.loadFavorites(offset: 0))),
                    .run { send in
                        for await _ in notificationCenter.notifications(named: .favoritesUpdated) {
                            await send(.internal(.refresh))
                        }
                    },
                    .run { send in
                        for await _ in notificationCenter.notifications(named: .sceneBecomeActive) {
                            await send(.view(.onSceneBecomeActive))
                        }
                    },
                    .run { send in
                        for await notification in notificationsClient.eventPublisher().values {
                            guard notification.isTopic else { continue }
                            await send(.internal(.refresh))
                        }
                    }
                ])
                
            case .view(.onNextAppear):
                return .send(.internal(.refresh))
                
            case .view(.onRefresh):
                guard !state.isLoading else { return .none }
                return .send(.internal(.refresh))
                
            case .view(.onSceneBecomeActive):
                if !state.isLoading {
                    return .send(.internal(.refresh))
                }
                return .none
                
            case let .view(.favoriteTapped(favorite, showUnread)):
                guard !showUnread else {
                    return .send(.delegate(.openTopic(id: favorite.topic.id, name: favorite.topic.name, goTo: .unread)))
                }
                
                if favorite.isForum {
                    return .send(.delegate(.openForum(id: favorite.topic.id, name: favorite.topic.name)))
                } else {
                    let goTo = state.appSettings.topicOpeningStrategy.asGoTo
                    return .send(.delegate(.openTopic(id: favorite.topic.id, name: favorite.topic.name, goTo: goTo)))
                }
 
            case .view(.contextOptionMenu(let action)):
                switch action {
                case .sort:
                    state.sort = SortFeature.State()
                    return .none
                    
                case .markAllAsRead:
                    return .concatenate(
                        .run { send in
                            let status = try await apiClient.readAllFavorites()
                            let success = ToastMessage(text: Localization.markAsReadSuccess, haptic: .success)
                            await toastClient.showToast(status ? success : .whoopsSomethingWentWrong)
                        },
                        
                        .send(.internal(.refresh))
                    )
                }
                
            case .view(.commonContextMenu(let action, let isForum)):
                switch action {
                case .copyLink(let id):
                    let show = isForum ? "showforum" : "showtopic"
                    pasteboardClient.copy("https://4pda.to/forum/index.php?\(show)=\(id)")
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.linkCopied, haptic: .success))
                    }
                    
                case .delete(let id):
                    return .concatenate(
                        .run { send in
                            let request = SetFavoriteRequest(id: id, action: .delete, type: isForum ? .forum : .topic)
                            let status = try await apiClient.setFavorite(request)
                            await toastClient.showToast(status ? .actionCompleted : .whoopsSomethingWentWrong)
                        },
                        
                        .send(.internal(.refresh))
                    )
                    
                case .setImportant(let id, let pin):
                    return .concatenate(
                        .run { send in
                            let request = SetFavoriteRequest(id: id, action: pin ? .pin : .unpin, type: isForum ? .forum : .topic)
                            let status = try await apiClient.setFavorite(request)
                            await toastClient.showToast(status ? .actionCompleted : .whoopsSomethingWentWrong)
                        },
                        
                        .send(.internal(.refresh))
                    )
                    
                case .markRead(let id):
                    return .concatenate(
                        .run { [id, isForum] send in
                            let status = try await apiClient.markRead(id: id, isTopic: !isForum)
                            await toastClient.showToast(status ? .actionCompleted : .whoopsSomethingWentWrong)
                        },
                        
                        .send(.internal(.refresh))
                    )
                }
                
            case let .view(.topicContextMenu(action, favorite)):
                switch action {
                case .goToEnd:
                    return .send(.delegate(.openTopic(id: favorite.topic.id, name: favorite.topic.name, goTo: .last)))

                case .notifyHatUpdate(let flag):
                    return .run { send in
                        await send(.view(.topicContextMenu(.notify(flag, .hatUpdate), favorite)))
                    }
                    
                case .notify(let flag, let notify):
                    return .concatenate(
                        .run { send in
                            let request = NotifyFavoriteRequest(id: favorite.topic.id, flag: flag, type: notify)
                            let status = try await apiClient.notifyFavorite(request)
                            let notifyTypeChangedToast = ToastMessage(text: Localization.notifyTypeChanged, haptic: .success)
                            await toastClient.showToast(status ? notifyTypeChangedToast : .whoopsSomethingWentWrong)
                        },
                        
                        .send(.internal(.refresh))
                    )
                }
                
            case .internal(.refresh):
                state.isRefreshing = true
                return .run { [offset = state.pageNavigation.offset] send in
                    await send(.internal(.loadFavorites(offset: offset)))
                }
                
            case let .internal(.loadFavorites(offset)):
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
                        await send(.internal(.favoritesResponse(.success(favorites))))
                    }
                } catch: { error, send in
                    await send(.internal(.favoritesResponse(.failure(error))))
                }
                
            case let .internal(.favoritesResponse(.success(response))):
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
                
            case let .internal(.favoritesResponse(.failure(error))):
                print("FAVORITES RESPONSE FAILURE: \(error)")
                reportFullyDisplayed(&state)
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
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
}
