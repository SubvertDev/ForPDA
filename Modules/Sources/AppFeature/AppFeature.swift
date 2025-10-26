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
        public var profileFlow:  ProfileFlow.State
        
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
            
            if let session = _userSession.wrappedValue {
                self.profileFlow = .loggedIn(StackTab.State(root: .profile(.profile(ProfileFeature.State(userId: session.userId)))))
            } else {
                self.profileFlow = .loggedOut(StackTab.State(root: .auth(AuthFeature.State(openReason: .profile))))
            }
            
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
        case profileFlow(ProfileFlow.Action)
        
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
        
        case userDidLogin(userId: Int)
        case userDidLogout
        
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
        
        Scope(state: \.profileFlow, action: \.profileFlow) {
            ProfileFlow.body
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
                    .run { [userSession = state.$userSession] send in
                        for await session in userSession.publisher.values.dropFirst() {
                            notificationCenter.post(name: .favoritesUpdated, object: nil)
                            if let session {
                                await send(.userDidLogin(userId: session.userId))
                            } else {
                                await send(.userDidLogout)
                            }
                        }
                    }.animation(),
                    
                    .run { send in
                        do {
                            try await apiClient.connect(inBackground: false)
                        } catch {
                            await send(._failedToConnect(error))
                        }
                    },
                    
                    .run { send in
                        for await state in apiClient.connectionState() {
                            await send(.connectionStateChanged(state))
                        }
                    },
                    
                    .run { send in
                        for await notification in apiClient.notificationStream() {
                            await send(.receivedNotification(notification))
                        }
                    },
                    
                    .run { send in
                        for await identifier in notificationsClient.delegate() {
                            await send(.notificationDeeplink(identifier))
                        }
                    },
                    
                    .run { send in
                        for await toast in toastClient.queue() {
                            await send(._showToast(toast))
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
                
            case .networkStateChanged(_):
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
                    let isProcessed = await notificationsClient.processNotification(notification)
                    if isProcessed {
                        let unread = try await apiClient.getUnread()
                        let skipCategories: [Unread.Item.Category] = [.topic, .forum]
                        await notificationsClient.showUnreadNotifications(unread, skipCategories: skipCategories)
                    }
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
                    if #available(iOS 26, *) {
                        // System tabbar handles scrolls/pops by itself
                        return removeNotifications(&state)
                    } else {
                        return handleSameTabSelection(&state)
                    }
                } else {
                    return handleOtherTabSelection(newTab: tab, &state)
                }
                
            case let .auth(.presented(.delegate(.loginSuccess(reason, _)))):
                // Also make necessary changes to delegate actions in StackTab
                switch reason {
                case .commentAction, .sendComment:
                    state.auth = nil
                case .profile:
                    let error = NSError(domain: "Profile login success is caught in AppFeature", code: 0)
                    analyticsClient.capture(error)
                }
                return .run { _ in
                    notificationCenter.post(name: .favoritesUpdated, object: nil)
                }
                
            case .auth:
                return .none
                
            case let .userDidLogin(userId: userId):
                state.profileFlow = .loggedIn(StackTab.State(root: .profile(.profile(ProfileFeature.State(userId: userId)))))
                return .none
                
            case .userDidLogout:
                state.profileFlow = .loggedOut(StackTab.State(root: .auth(AuthFeature.State(openReason: .profile))))
                return .none
                
                
                // MARK: - Deeplinks
                
                #warning("merge these two actions somehow")
                
            case let .deeplink(url):
                do {
                    let deeplink = try DeeplinkHandler().handleOuterToInnerURL(url)
                    return showScreenForDeeplink(deeplink, &state)
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
                    return showScreenForDeeplink(deeplink, &state)
                } catch {
                    analyticsClient.capture(error)
                    state.alert = AlertState {
                        TextState("Unable to open link", bundle: .module)
                    }
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
                let .profileFlow(.loggedIn(.delegate(.showTabBar(show)))),
                let .profileFlow(.loggedOut(.delegate(.showTabBar(show)))):
                state.showTabBar = show
                return .none
                
            case let .articlesTab(.delegate(.switchTab(to: tab))),
                let .favoritesTab(.delegate(.switchTab(to: tab))),
                let .forumTab(.delegate(.switchTab(to: tab))),
                let .profileFlow(.loggedIn(.delegate(.switchTab(to: tab)))),
                let .profileFlow(.loggedOut(.delegate(.switchTab(to: tab)))):
                state.previousTab = state.selectedTab
                state.selectedTab = tab
                return .none
                
            case .articlesTab, .favoritesTab, .forumTab, .profileFlow:
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
    
    @available(iOS, deprecated: 26, message: "System tabbar handles scrolls/pops by itself")
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
            state.favoritesTab.path.removeAll()
            
        case .forum:
            state.forumTab.path.removeAll()

        case .profile:
            switch state.profileFlow {
            case var .loggedIn(flow):
                if !flow.path.isEmpty {
                    flow.path.removeAll()
                    state.profileFlow[case: \.loggedIn] = flow
                }
            case var .loggedOut(flow):
                if !flow.path.isEmpty {
                    flow.path.removeAll()
                    state.profileFlow[case: \.loggedOut] = flow
                }
            }
        }
        
        return removeNotifications(&state)
    }
    
    private func handleOtherTabSelection(newTab: AppTab, _ state: inout State) -> Effect<Action> {
        state.previousTab = state.selectedTab
        state.selectedTab = newTab
        return removeNotifications(&state)
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
    
    private func showScreenForDeeplink(_ deeplink: Deeplink, _ state: inout State) -> Effect<Action> {
        let screen: Path.State
        switch deeplink {
        case let .article(id, _, _):
            let preview = ArticlePreview.innerDeeplink(id: id)
            screen = .articles(.article(ArticleFeature.State(articlePreview: preview)))
        case let .announcement(id):
            screen = .forum(.announcement(AnnouncementFeature.State(id: id)))
        case let .topic(id, goTo):
            screen = .forum(.topic(TopicFeature.State(topicId: id!, goTo: goTo)))
        case let .forum(id, page):
            screen = .forum(.forum(ForumFeature.State(forumId: id, initialPage: page)))
        case let .user(id):
            screen = .profile(.profile(ProfileFeature.State(userId: id)))
        }
        
        openScreenOnCurrentStack(screen, state: &state)
        
        return .none
    }
    
    private func openScreenOnCurrentStack(_ element: Path.State, state: inout State) {
        switch state.selectedTab {
        case .articles:  state.articlesTab.path.append(element)
        case .favorites: state.favoritesTab.path.append(element)
        case .forum:     state.forumTab.path.append(element)
        case .profile:
            switch state.profileFlow {
            case var .loggedIn(flow):
                flow.path.append(element)
                state.profileFlow[case: \.loggedIn] = flow
            case var .loggedOut(flow):
                flow.path.append(element)
                state.profileFlow[case: \.loggedOut] = flow
            }
        }
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
