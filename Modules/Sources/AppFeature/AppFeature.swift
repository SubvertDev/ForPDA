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
import FavoritesFeature
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
import SearchResultFeature
import CacheClient
import DeviceSpecificationsFeature
import DeviceTypeFeature

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
        
        public var favoritesBadges = 0
        public var profileBadges = 0
        
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
            favoritesTab: StackTab.State = StackTab.State(root: .favorites(FavoritesFeature.State())),
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
        case scenePhaseDidChange(from: ScenePhase, to: ScenePhase)
        case registerBackgroundTask
        case backgroundTaskInvoked
        case didFinishToastAnimation
        case updateBadges(Unread)
        
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
                            apiClient.setLogResponses(.none)
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
                        for await unread in notificationsClient.unreadPublisher().values {
                            await send(.updateBadges(unread))
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
                        let unread = try await apiClient.getUnread(type: .all)
                        await notificationsClient.showUnreadNotifications(unread, skipCategories: [])
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
                
            case let .updateBadges(unread):
                let favoritesBadges =
                (state.appSettings.notifications.isForumEnabled ? unread.forumCount : 0) +
                (state.appSettings.notifications.isTopicsEnabled ? unread.topicCount : 0)
                
                // Sometimes we have more favorites in general count than in an array, so we apply min() fix
                state.favoritesBadges = min(unread.favoritesUnreadCount, favoritesBadges)
                
                let profileBadges =
                (state.appSettings.notifications.isQmsEnabled ? unread.qmsUnreadCount : 0) +
                (state.appSettings.notifications.isSiteMentionsEnabled ? unread.siteMentionsCount : 0) +
                (state.appSettings.notifications.isForumMentionsEnabled ? unread.forumMentionsCount : 0)
                state.profileBadges = profileBadges
                
                cacheClient.setUnread(unread)
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
                
            case .binding, .alert:
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
                return .run { _ in
                    do {
                        let unread = try await apiClient.getUnread(type: .all)
                        await notificationsClient.showUnreadNotifications(unread, skipCategories: [])
                    } catch {
                        analyticsClient.capture(error)
                    }
                }
                
            case .userDidLogout:
                state.profileFlow = .loggedOut(StackTab.State(root: .auth(AuthFeature.State(openReason: .profile))))
                state.favoritesBadges = 0
                state.profileBadges = 0
                return .run { _ in
                    notificationsClient.setNotificationContext(context: nil)
                    await notificationsClient.removeNotifications(
                        categories: [.qms, .forum, .topic, .forumMention, .siteMention]
                    )
                    await notificationsClient.showUnreadNotifications(.mockEmpty, skipCategories: [])
                }
                
                
                // MARK: - Deeplinks
                
                // TODO: Merge these two actions below somehow
                
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
                
            case let .appDelegate(.userNotification(identifier)):
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
                        
                        if isLoggedIn {
                            let unread = try await apiClient.getUnread(type: .all)
                            await notificationsClient.showUnreadNotifications(unread, skipCategories: [])
                        }
                    }
                    
                    if newPhase == .background {
                        if isLoggedIn {
                            await send(.registerBackgroundTask)
                        }
                        try await apiClient.disconnect()
                    }
                }
                
            case .registerBackgroundTask:
                // return .send(.syncUnreadTaskInvoked) // For test purposes
                guard state.appSettings.backgroundNotifications2 else { return .none }
                
                let request = BGAppRefreshTaskRequest(identifier: state.notificationsId)
                request.earliestBeginDate = .now.addingTimeInterval(15 * 60) // 15 minutes by default
                do {
                    try BGTaskScheduler.shared.submit(request)
                    logger.info("[AppRefresh] Successfully scheduled BGAppRefreshTaskRequest")
                    // Set breakpoint here and run:
                    // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.subvert.forpda.background.notifications"]
                } catch {
                    analyticsClient.capture(error)
                }
                return .none
                
            case .backgroundTaskInvoked:
                return .run { [appSettings = state.appSettings] send in
                    do {
                        
                        guard try await notificationsClient.hasPermission() else { return }
                        logger.info("[AppRefresh] Notifications permission is granted")
                        
                        guard appSettings.notifications.isAnyEnabled else { return }
                        logger.info("[AppRefresh] Notifications enabled in settings")
                        
                        try await apiClient.connect(inBackground: true)
                        logger.info("[AppRefresh] Successfully connected. Fetching notifications...")
                        
                        let unread = try await apiClient.getUnread(type: .all)
                        logger.info("[AppRefresh] Successfully fetched. Preparing to show notifications..")
                        
                        await notificationsClient.showUnreadNotifications(unread, [])
                        logger.info("[AppRefresh] Successfully shown notifications")
                        
                    } catch {
                        analyticsClient.capture(error)
                    }
                }
                
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
                
            case .appDelegate:
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
                break
                // await notificationsClient.removeNotifications(categories: [.forum, .topic])
            }
        }
    }
    
    private func refreshFavoritesTab(_ state: inout State) -> Effect<Action> {
        return StackTab()
            .reduce(into: &state.favoritesTab, action: .root(.favorites(.internal(.refresh))))
            .map(Action.favoritesTab)
    }
    
    private func showScreenForDeeplink(_ deeplink: Deeplink, _ state: inout State) -> Effect<Action> {
        let screen: Path.State
        switch deeplink {
        case let .article(id, _, _, scrollToId):
            let preview = ArticlePreview.innerDeeplink(id: id)
            screen = .articles(.article(ArticleFeature.State(articlePreview: preview, scrollToId: scrollToId)))
        case let .announcement(id):
            screen = .forum(.announcement(AnnouncementFeature.State(id: id)))
        case let .device(goTo):
            switch goTo {
            case .index:
                screen = .devDB(.type(DeviceTypeFeature.State(content: .index)))
            case .brands(let type):
                screen = .devDB(.type(DeviceTypeFeature.State(content: .brands(type))))
            case .vendor(let vendorName, let type):
                screen = .devDB(.type(DeviceTypeFeature.State(content: .vendor(vendorName, type: type))))
            case .device(let tag, let subTag):
                screen = .devDB(.specifications(DeviceSpecificationsFeature.State(tag: tag, subTag: subTag)))
            }
        case let .topic(id, goTo):
            screen = .forum(.topic(TopicFeature.State(topicId: id!, goTo: goTo)))
        case let .forum(id, page):
            screen = .forum(.forum(ForumFeature.State(forumId: id, initialPage: page)))
        case let .user(id):
            screen = .profile(.profile(ProfileFeature.State(userId: id)))
        case let .qms(id: id):
            screen = .qms(.qms(QMSFeature.State(chatId: id)))
        case let .search(options: options):
            screen = .search(.searchResult(SearchResultFeature.State(search: options)))
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
