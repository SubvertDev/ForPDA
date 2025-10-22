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
import ReputationFeature
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
import Combine

@Reducer
public struct AppFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    public enum Localization {
        static let connecting = LocalizedStringResource("Connecting...", bundle: .module)
        static let noInternetConnection = LocalizedStringResource("No internet connection", bundle: .module)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var appDelegate: AppDelegateFeature.State
        
        public var articlesTab:  StackTab.State
        public var favoritesTab: StackTab.State
        public var forumTab:     StackTab.State
        public var profileTab:   StackTab.State
        
        @Presents public var auth: AuthFeature.State?
        @Presents public var logStore: LogStoreFeature.State?
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
        
        public var connectionState: ConnectionState = .disconnected
        public var isNetworkOnline = true
        
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
        case onShake
        
        case appDelegate(AppDelegateFeature.Action)
        
        case articlesTab(StackTab.Action)
        case favoritesTab(StackTab.Action)
        case forumTab(StackTab.Action)
        case profileTab(StackTab.Action)
        
        case auth(PresentationAction<AuthFeature.Action>)
        case logStore(PresentationAction<LogStoreFeature.Action>)
        case alert(PresentationAction<Never>)
        
        case binding(BindingAction<State>) // For Toast
        case didSelectTab(AppTab)
        case deeplink(URL)
        case notificationDeeplink(String)
        case scenePhaseDidChange(from: ScenePhase, to: ScenePhase)
        case registerBackgroundTask
        case backgroundTaskInvoked
        case didFinishToastAnimation
        
        case connectionStateChanged(ConnectionState)
        case networkStateChanged(Bool)
        case receivedNotification(String)
        
        case _showToast(ToastMessage)
        case _showErrorToast
        case _failedToConnect(any Error)
    }
    
    // MARK: - CancelID
    
    enum CancelID {
        case showToast
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.logger[.app])         private var logger
    @Dependency(\.apiClient)            private var apiClient
    @Dependency(\.cacheClient)          private var cacheClient
    @Dependency(\.toastClient)          private var toastClient
    @Dependency(\.hapticClient)         private var hapticClient
    @Dependency(\.analyticsClient)      private var analyticsClient
    @Dependency(\.notificationCenter)   private var notificationCenter
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
                return .merge(
                    .run { send in
                        await withTaskGroup { group in
                            group.addTask {
                                do {
                                    try await apiClient.connect(inBackground: false)
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
                            
                            group.addTask {
                                for await state in apiClient.connectionState() {
                                    await send(.connectionStateChanged(state))
                                }
                            }
                            
                            group.addTask {
                                for await notification in apiClient.notificationStream() {
                                    await send(.receivedNotification(notification))
                                }
                            }
                        }
                    }
                )
                
            case let .connectionStateChanged(connectionState):
                state.connectionState = connectionState
                // switch connectionState {
                // case .ready:
                //     state.toastMessage = nil
                // case .connecting:
                //     state.toastMessage = ToastMessage(
                //         text: Localization.connecting,
                //         duration: 999_999_999,
                //         priority: .high
                //     )
                // case .disconnected:
                //     if !state.isNetworkOnline {
                //         state.toastMessage = ToastMessage(
                //             text: Localization.noInternetConnection,
                //             isError: true,
                //             duration: 999_999_999,
                //             priority: .high
                //         )
                //     }
                // }
                return .none
                
            case let .networkStateChanged(networkState):
                // let noInternet = ToastMessage(
                //     text: Localization.noInternetConnection,
                //     isError: true,
                //     duration: 999_999_999,
                //     priority: .high
                // )
                // state.toastMessage = networkState ? nil : noInternet
                // state.isNetworkOnline = networkState
                return .none
                
            case let .receivedNotification(notification):
                return .run { _ in
                    await notificationsClient.processNotification(notification)
                }
                
            case .onShake:
                #if DEBUG
                state.logStore = LogStoreFeature.State()
                #endif
                return .none
                
            case .logStore:
                return .none
                
            case let ._showToast(toast):
                guard toast.priority >= state.toastMessage?.priority ?? .low else { return .none }
                state.toastMessage = toast
                return .run { send in
                    try await Task.sleep(for: .seconds(toast.duration))
                    guard !Task.isCancelled else { return }
                    await send(.didFinishToastAnimation)
                }
                .cancellable(id: CancelID.showToast)
                .merge(with: .cancel(id: CancelID.showToast))
                
            case .didFinishToastAnimation:
                state.toastMessage = nil
                return .none
                
            case ._failedToConnect:
                return .run { _ in
                    // if let error = error as? PDAPIError {
                    //     switch error {
                    //     case .noInternet:
                    //         let toast = ToastMessage(
                    //             text: Localization.noInternetConnection,
                    //             isError: true,
                    //             duration: 999_999_999,
                    //             priority: .high
                    //         )
                    //         await toastClient.showToast(toast)
                    //     case .notDisconnected, .authStateNotSet, .invalidBootstrap:
                    //         analyticsClient.capture(error)
                    //     }
                    // } else {
                    //     await toastClient.showToast(.whoopsSomethingWentWrong)
                    //     analyticsClient.capture(error)
                    // }
                }
                
            case ._showErrorToast:
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case .appDelegate, .binding, .alert:
                return .none
                
            case let .didSelectTab(tab):
                if state.selectedTab == tab {
                    return handleSameTabSelection(&state)
                } else {
                    return handleOtherTabSelection(newTab: tab, &state)
                }
                
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
                
            case let .deeplink(url):
                do {
                    let deeplink = try DeeplinkHandler().handleOuterToInnerURL(url)
                    switch deeplink {
                    case let .article(id, title, imageUrl):
                        let preview = ArticlePreview.outerDeeplink(id: id, imageUrl: imageUrl, title: title)
                        let articleState = ArticleFeature.State(articlePreview: preview)
                        openScreenOnCurrentStack(.articles(.article(articleState)), state: &state)
                    case let .announcement(id):
                        let announceState = AnnouncementFeature.State(id: id)
                        openScreenOnCurrentStack(.forum(.announcement(announceState)), state: &state)
                    case let .topic(id, goTo):
                        let topicState = TopicFeature.State(topicId: id!, goTo: goTo)
                        openScreenOnCurrentStack(.forum(.topic(topicState)), state: &state)
                    case let .forum(id, page):
                        let forumState = ForumFeature.State(forumId: id, initialPage: page)
                        openScreenOnCurrentStack(.forum(.forum(forumState)), state: &state)
                    case let .user(id):
                        let profileState = ProfileFeature.State(userId: id)
                        openScreenOnCurrentStack(.profile(.profile(profileState)), state: &state)
                    }
                } catch {
                    analyticsClient.capture(error)
                    state.alert = AlertState {
                        TextState("Unable to open link", bundle: .module)
                    }
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
                    if newPhase == .active {
                        try? await apiClient.connect(inBackground: false)
                        notificationCenter.post(name: .sceneBecomeActive, object: nil)
                    }
                    
                    if isLoggedIn, newPhase == .background {
                        // await send(.registerBackgroundTask)
                    }
                    
                    if newPhase == .background {
                        try await apiClient.disconnect()
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
                
            case .backgroundTaskInvoked:
                return .none
                
                // TEMPORARY DISABLED DUE TO BACKGROUND PAUSE BUG
                
                // return .run { [appSettings = state.appSettings] send in
                //     do {
                //         // Refresh task might pause in background and resume in foreground
                //         // hence we need to always check current application state
                //         let appState = await UIApplication.shared.applicationState
                //         logger.warning("Background task invoked on '\(appState.description, privacy: .public)' state")
                //
                //         guard await UIApplication.shared.applicationState == .background else { return }
                //         guard try await notificationsClient.hasPermission() else { return }
                //         guard appSettings.notifications.isAnyEnabled else { return }
                //
                //         try await apiClient.connect(inBackground: true)
                //         let unread = try await apiClient.getUnread()
                //
                //         guard await UIApplication.shared.applicationState == .background else { return }
                //         logger.warning("Preparing to show unread notifications")
                //         await notificationsClient.showUnreadNotifications(unread, [])
                //         logger.warning("Did show unread notifications")
                //
                //         guard await UIApplication.shared.applicationState == .background else { return }
                //         logger.warning("STOPPING CONNECTION ON BG TASK REQUEST")
                //         try await apiClient.disconnect()
                //     } catch {
                //         analyticsClient.capture(error)
                //     }
                //
                //     await send(.registerBackgroundTask)
                // }
                
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
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$auth, action: \.auth) {
            AuthFeature()
        }
        .ifLet(\.$logStore, action: \.logStore) {
            LogStoreFeature()
        }
    }
    
    // MARK: - Private Functions
    
    private func handleSameTabSelection(_ state: inout State) -> Effect<Action> {
        if state.selectedTab == .articles, state.articlesTab.path.isEmpty {
            // Scroll to top of articles
            return StackTab()
                .reduce(into: &state.articlesTab, action: .root(.articles(.articlesList(.scrollToTop))))
                .map(Action.articlesTab)
        }
        
        switch state.selectedTab {
        case .articles:
            //
            if state.articlesTab.path.isEmpty {
                return StackTab()
                    .reduce(into: &state.articlesTab, action: .root(.articles(.articlesList(.scrollToTop))))
                    .map(Action.articlesTab)
            } else {
                // TODO: enum
                let error = NSError(domain: "Impossible articles tab action", code: 0)
                analyticsClient.capture(error)
            }
            
        case .favorites:
            if !state.favoritesTab.path.isEmpty {
                state.favoritesTab.path.removeAll()
                return .concatenate(
                    removeNotifications(&state),
                    refreshFavoritesTab(&state)
                )
            }
            
        case .forum:
            state.forumTab.path.removeAll()

        case .profile:
            state.profileTab.path.removeAll()
        }
        
        return removeNotifications(&state)
    }
    
    private func handleOtherTabSelection(newTab: AppTab, _ state: inout State) -> Effect<Action> {
        if newTab == .profile && !state.isAuthorized {
            state.auth = AuthFeature.State(openReason: .profile)
        } else {
            state.previousTab = state.selectedTab
            state.selectedTab = newTab
        }
        return removeNotifications(&state)
    }
    
    private func openScreenOnCurrentStack(_ element: Path.State, state: inout State) {
        switch state.selectedTab {
        case .articles:  state.articlesTab.path.append(element)
        case .favorites: state.favoritesTab.path.append(element)
        case .forum:     state.forumTab.path.append(element)
        case .profile:   state.profileTab.path.append(element)
        }
    }
    
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
            targetState = .topic(TopicFeature.State(topicId: id!, goTo: goTo))
        case let .forum(id, page):
            targetState = .forum(ForumFeature.State(forumId: id, initialPage: page))
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

// MARK: - Extensions

extension UIApplication.State {
    var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            fatalError()
        }
    }
}
