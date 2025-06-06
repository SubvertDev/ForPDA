//
//  AppFeature.swift
//
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import SwiftUI
import ComposableArchitecture
import DeeplinkHandler
import ArticlesListFeature
import ArticleFeature
import BookmarksFeature
import ForumsListFeature
import ForumFeature
import TopicFeature
import AnnouncementFeature
import FavoritesRootFeature
import HistoryFeature
import AuthFeature
import ProfileFeature
import QMSListFeature
import QMSFeature
import SettingsFeature
import NotificationsFeature
import DeveloperFeature
import APIClient
import Models
import TCAExtensions
import BackgroundTasks
import LoggerClient
import NotificationsClient
import ToastClient

@Reducer
public struct AppFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var appDelegate: AppDelegateFeature.State
        
        public var articlesTab:  StackTab.State
        public var favoritesTab: StackTab.State
        public var forumTab:     StackTab.State
        public var profileTab:   StackTab.State
        
        @Presents public var auth: AuthFeature.State?
        @Presents public var alert: AlertState<Never>?
        
        @Shared(.userSession) public var userSession: UserSession?
        @Shared(.appSettings) public var appSettings: AppSettings
        
        public var selectedTab: AppTab
        public var previousTab: AppTab
        public var showTabBar: Bool
        public var toastMessage: ToastMessage?
        
        public var isAuthorized: Bool {
            return userSession != nil
        }
        
        public var notificationsId: String {
            let identifiers = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String]
            return identifiers?.first ?? ""
        }
        
        public init(
            appDelegate: AppDelegateFeature.State = AppDelegateFeature.State(),
            articlesTab: StackTab.State = StackTab.State(root: .articles(.articlesList(ArticlesListFeature.State()))),
            favoritesTab: StackTab.State = StackTab.State(root: .favorites(FavoritesRootFeature.State())),
            forumTab: StackTab.State = StackTab.State(root: .forum(.forumList(ForumsListFeature.State()))),
            profileTab: StackTab.State = StackTab.State(root: .profile(.profile(ProfileFeature.State()))),
            auth: AuthFeature.State? = nil,
            alert: AlertState<Never>? = nil,
            selectedTab: AppTab = .articles,
            previousTab: AppTab = .articles,
            isShowingTabBar: Bool = true,
            toastMessage: ToastMessage? = nil
        ) {
            self.appDelegate = appDelegate
            
            self.articlesTab = articlesTab
            self.favoritesTab = favoritesTab
            self.forumTab = forumTab
            self.profileTab = profileTab
            
            self.auth = auth
            self.alert = alert
            
            self.selectedTab = selectedTab
            self.previousTab = previousTab
            self.showTabBar = isShowingTabBar
            
            self.toastMessage = toastMessage
            
            self.selectedTab = _appSettings.startPage.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        
        case appDelegate(AppDelegateFeature.Action)
        
        case articlesTab(StackTab.Action)
        case favoritesTab(StackTab.Action)
        case forumTab(StackTab.Action)
        case profileTab(StackTab.Action)
        
        case auth(PresentationAction<AuthFeature.Action>)
        case alert(PresentationAction<Never>)
        
        case binding(BindingAction<State>) // For Toast
        case didSelectTab(AppTab)
        case deeplink(URL)
        case notificationDeeplink(String)
        case scenePhaseDidChange(from: ScenePhase, to: ScenePhase)
        case registerBackgroundTask
        case syncUnreadTaskInvoked
        case didFinishToastAnimation
        
        case _showToast(ToastMessage)
        case _showErrorToast
        case _failedToConnect(any Error)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.logger[.app])         private var logger
    @Dependency(\.apiClient)            private var apiClient
    @Dependency(\.cacheClient)          private var cacheClient
    @Dependency(\.toastClient)          private var toastClient
    @Dependency(\.hapticClient)         private var hapticClient
    @Dependency(\.analyticsClient)      private var analyticsClient
    @Dependency(\.notificationsClient)  private var notificationsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateFeature()
        }
        
        Scope(state: \.articlesTab, action: \.articlesTab) {
            StackTab()
        }
        
        Scope(state: \.favoritesTab, action: \.favoritesTab) {
            StackTab()
        }
        
        Scope(state: \.forumTab, action: \.forumTab) {
            StackTab()
        }
        
        Scope(state: \.profileTab, action: \.profileTab) {
            StackTab()
        }
        
        // Authorization actions interceptor
        Reduce<State, Action> { state, action in
            switch action {
            case .articlesTab(.path(.element(id: _, action: .articles(.article(.comments(.element(id: _, action: .delegate(.unauthorizedAction)))))))):
                state.auth = AuthFeature.State(openReason: .commentAction)
                
            case .articlesTab(.path(.element(id: _, action: .articles(.article(.delegate(.unauthorizedAction)))))):
                state.auth = AuthFeature.State(openReason: .sendComment)
                
            default:
                break
            }
            
            return .none
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await withTaskGroup { group in
                        group.addTask {
                            do {
                                await apiClient.setLogResponses(.none)
                                try await apiClient.connect()
                            } catch {
                                await send(._failedToConnect(error))
                            }
                        }
                        
                        group.addTask {
                            for await toast in toastClient.queue() {
                                await send(._showToast(toast))
                            }
                        }
                        
                        group.addTask {
                            for await identifier in notificationsClient.delegate() {
                                await send(.notificationDeeplink(identifier))
                            }
                        }
                    }
                }
                
            case let ._showToast(toast):
                state.toastMessage = toast
                return .none
                
            case .didFinishToastAnimation:
                state.toastMessage = nil
                return .none
                
            case ._failedToConnect:
                state.alert = .failedToConnect
                return .none
                
            case ._showErrorToast:
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case .appDelegate, .binding, .alert:
                return .none
                
            case let .didSelectTab(tab):
                if state.selectedTab == tab {
                    if tab == .articles, state.articlesTab.path.isEmpty {
                        // state.articlesTab.root.articles?.articlesList?.scrollToTop()
                        return StackTab()
                            .reduce(into: &state.articlesTab, action: .root(.articles(.articlesList(.scrollToTop))))
                            .map(Action.articlesTab)
                    }
                } else {
                    if tab == .profile && !state.isAuthorized {
                        state.auth = AuthFeature.State(openReason: .profile)
                        // Opening tab only after auth via delegate action
                    } else {
                        state.previousTab = state.selectedTab
                        state.selectedTab = tab
                    }
                }
                
                // Updating favorites on tab selection
                if state.selectedTab == .favorites && state.previousTab != .favorites {
                    state.favoritesTab.path.removeAll()
                    
                    return .concatenate(
                        removeNotifications(&state),
                        refreshFavoritesTab(&state)
                    )
                }
                
                if state.selectedTab == .forum && state.previousTab != .forum {
                    state.forumTab.path.removeAll()
                }
                
                if state.selectedTab == .profile && state.previousTab != .profile {
                    state.forumTab.path.removeAll()
                }
                
                return removeNotifications(&state)
                
            case let .auth(.presented(.delegate(.loginSuccess(reason, _)))):
                state.auth = nil
                if reason == .profile {
                    state.previousTab = state.selectedTab
                    state.selectedTab = .profile
                }
                return .none
                
            case .auth:
                return .none
                
                // MARK: - Deeplink
                
            case .deeplink(let url):
                do {
                    let deeplink = try DeeplinkHandler().handleOuterToInnerURL(url)
                    // TODO: Handles only articles cases for now
                    if case let .article(id: id, title: title, imageUrl: imageUrl) = deeplink {
                        let preview = ArticlePreview.outerDeeplink(id: id, imageUrl: imageUrl, title: title)
                        // TODO: Do I need to set previous tab here?
                        state.selectedTab = .articles
                        state.articlesTab.path.append(.articles(.article(ArticleFeature.State(articlePreview: preview))))
                    }
                } catch {
                    analyticsClient.capture(error)
                    // TODO: Show error in UI?
                }
                return .none
                
            case let .notificationDeeplink(identifier):
                do {
                    let deeplink = try DeeplinkHandler().handleNotification(identifier)
                    return handleNotificationDeeplink(deeplink, &state)
                } catch {
                    analyticsClient.capture(error)
                    // TODO: Show error in UI?
                }
                return .none
                
                // MARK: - ScenePhase
                
            case let .scenePhaseDidChange(from: _, to: newPhase):
                return .run { [isLoggedIn = state.userSession != nil] send in
                    if newPhase == .background {
                        await send(.registerBackgroundTask)
                    }
                    if isLoggedIn && (newPhase == .background || newPhase == .active) {
                        // Avoiding double invoke due to "active > inactive > background"
                        await send(.syncUnreadTaskInvoked)
                    }
                }
                
            case .registerBackgroundTask:
                // return .send(.syncUnreadTaskInvoked) // For test purposes
                let request = BGAppRefreshTaskRequest(identifier: state.notificationsId)
                do {
                    try BGTaskScheduler.shared.submit(request)
                    logger.info("Successfully scheduled BGAppRefreshTaskRequest")
                    // Set breakpoint here and run:
                    // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.subvert.forpda.background.notifications"]
                } catch {
                    analyticsClient.capture(error)
                }
                return .none
                
            case .syncUnreadTaskInvoked:
                return .run { [appSettings = state.appSettings, tab = state.selectedTab] send in
                    do {
                        guard try await notificationsClient.hasPermission() else { return }
                        guard appSettings.notifications.isAnyEnabled else { return }
                        
                        // try await apiClient.connect() // TODO: Do I need this?
                        let unread = try await apiClient.getUnread()
                        var skipCategories: [Unread.Item.Category] = []
                        // TODO: Add more skip cases later
                        switch tab {
                        case .articles, .forum, .profile:
                            break
                        case .favorites:
                            skipCategories.append(.forum)
                            skipCategories.append(.topic)
                        }
                        await notificationsClient.showUnreadNotifications(unread, skipCategories)
                        
                        // TODO: Make at an array?
                        let invokeTime = Date().timeIntervalSince1970
                        await cacheClient.setLastBackgroundTaskInvokeTime(invokeTime)
                    } catch {
                        analyticsClient.capture(error)
                        await send(._showErrorToast)
                    }
                    
                    await send(.registerBackgroundTask)
                }
                
            case let .articlesTab(.delegate(.showTabBar(show))),
                let .favoritesTab(.delegate(.showTabBar(show))),
                let .forumTab(.delegate(.showTabBar(show))),
                let .profileTab(.delegate(.showTabBar(show))):
                state.showTabBar = show
                return .none
                
            case let .articlesTab(.delegate(.switchTab(to: tab))),
                let .favoritesTab(.delegate(.switchTab(to: tab))),
                let .forumTab(.delegate(.switchTab(to: tab))),
                let .profileTab(.delegate(.switchTab(to: tab))):
                state.previousTab = state.selectedTab
                state.selectedTab = tab
                return .none
                
            case .articlesTab, .favoritesTab, .forumTab, .profileTab:
                return .none
            }
        }
        .ifLet(\.$auth, action: \.auth) {
            AuthFeature()
        }
    }
    
    // MARK: - Private Functions
    
    private func removeNotifications(_ state: inout State) -> Effect<Action> {
        return .run { [tab = state.selectedTab] _ in
            switch tab {
            case .articles, .forum, .profile:
                break
            case .favorites:
                await notificationsClient.removeNotifications(categories: [.forum, .topic])
            }
        }
    }
    
    private func refreshFavoritesTab(_ state: inout State) -> Effect<Action> {
        return StackTab()
            .reduce(into: &state.favoritesTab, action: .root(.favorites(.favorites(.internal(.refresh)))))
            .map(Action.favoritesTab)
    }
    
    private func handleNotificationDeeplink(_ deeplink: Deeplink, _ state: inout State) -> Effect<Action> {
        if case .user = deeplink {
            return .none
        }
        
        // Handling article deeplink
        
        if case let .article(id, _, _) = deeplink {
            if state.selectedTab != .articles {
                state.previousTab = state.selectedTab
                state.selectedTab = .articles
            }
            state.articlesTab.path.append(.articles(.article(ArticleFeature.State.init(articlePreview: ArticlePreview.innerDeeplink(id: id)))))
            return .none
        }
        
        // Handling forum deeplinks
        
        let isOnForumHandledTab = state.selectedTab == .favorites || state.selectedTab == .forum
        
        let targetState: Path.Forum.Body.State
        switch deeplink {
        case let .announcement(id):
            targetState = .announcement(AnnouncementFeature.State(id: id))
        case let .topic(id, goTo):
            targetState = .topic(TopicFeature.State(topicId: id, goTo: goTo))
        case let .forum(id):
            targetState = .forum(ForumFeature.State(forumId: id))
        default:
            fatalError("Unhandled notifications deeplink")
        }
        
        if isOnForumHandledTab {
            if state.selectedTab == .favorites {
                state.favoritesTab.path.append(.forum(targetState))
            }
            if state.selectedTab == .forum {
                state.forumTab.path.append(.forum(targetState))
            }
        } else {
            state.previousTab = state.selectedTab
            state.selectedTab = .forum
            state.forumTab.path.append(.forum(targetState))
        }
        
        return .none
    }
}
