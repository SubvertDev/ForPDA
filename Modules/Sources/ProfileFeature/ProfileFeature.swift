//
//  ProfileFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import PersistenceKeys
import Models
import AnalyticsClient
import ToastClient
import NotificationsClient
import FormFeature

@Reducer
public struct ProfileFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    private enum Localization {
        static let noteAdded = LocalizedStringResource("Note added", bundle: .module)
        static let profileUpdated = LocalizedStringResource("Profile updated", bundle: .module)
        static let profileUpdateError = LocalizedStringResource("Profile update error", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        case alert(AlertState<ProfileFeature.Action.Alert>)
        case note(FormFeature)
        case editProfile(EditFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        @Shared(.userSession) public var userSession: UserSession?
        public var userSessionGroup: User.Group?
        
        public let userId: Int?
        public var isLoading: Bool
        public var user: User?
        var qmsBadgeCount = 0
        var mentionsBadgeCount = 0
        
        public var shouldShowToolbarButtons: Bool {
            return userSession != nil && user?.id == userSession?.userId
        }
        
        var isUserSessionHasModerationGroup: Bool {
            return userSessionGroup == .admin
                || userSessionGroup == .supermoderator
                || userSessionGroup == .moderator
                || userSessionGroup == .moderatorHelper
                || userSessionGroup == .moderatorSchool
        }
        
        var didLoadOnce = false
        
        public init(
            userId: Int? = nil,
            isLoading: Bool = true,
            user: User? = nil
        ) {
            self.userId = userId
            self.isLoading = isLoading
            self.user = user
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)

        case view(View)
        public enum View {
            case onAppear
            case qmsButtonTapped
            case settingsButtonTapped
            case logoutButtonTapped
            case historyButtonTapped
            case mentionsButtonTapped
            case reputationButtonTapped
            case searchTopicsButtonTapped
            case searchRepliesButtonTapped
            case deviceButtonTapped(String)
            case curatedTopicButtonTapped(Int)
            case deeplinkTapped(URL, ProfileDeeplinkType)
            
            case contextMenu(ProfileContextMenuAction)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case userResponse(Result<User, any Error>)
            case updateBadgeCounts(Unread)
            case updateUserSessionGroup(User.Group)
        }
        
        case destination(PresentationAction<Destination.Action>)
        public enum Alert: Equatable {
            case logout
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openQms
            case openSettings
            case openHistory
            case openMentions
            case openDevice(String)
            case openTopic(Int)
            case openReputation(Int)
            case openSearch(SearchResult)
            case handleUrl(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.notificationCenter) private var notificationCenter
    @Dependency(\.notificationsClient) private var notificationsClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                let userId = state.userId == nil ? state.userSession?.userId : state.userId
                guard let userId else { return .none }
                return .merge(
                    .run { send in
                        for try await user in try await apiClient.getUser(userId, .cacheAndLoad) {
                            await send(.internal(.userResponse(.success(user))))
                        }
                    } catch: { error, send in
                        await send(.internal(.userResponse(.failure(error))))
                    },
                    .run { [session = state.userSession] send in
                        if let session, let user = cacheClient.getUser(session.userId) {
                            await send(.internal(.updateUserSessionGroup(user.group)))
                        }
                    },
                    .run { send in
                        let unread = try await apiClient.getUnread(type: .all)
                        await notificationsClient.showUnreadNotifications(unread, skipCategories: [])
                    },
                    .run { send in
                        for await unread in notificationsClient.unreadPublisher().values {
                            await send(.internal(.updateBadgeCounts(unread)))
                        }
                    }
                )
                
            case let .view(.deviceButtonTapped(tag)):
                return .send(.delegate(.openDevice(tag)))
                
            case .view(.historyButtonTapped):
                return .send(.delegate(.openHistory))
                
            case .view(.mentionsButtonTapped):
                return .send(.delegate(.openMentions))
                
            case .view(.reputationButtonTapped):
                let userId = state.userId == nil ? state.userSession?.userId : state.userId
                guard let userId else { return .none }
                return .send(.delegate(.openReputation(userId)))
                
            case let .view(.curatedTopicButtonTapped(id)):
                return .send(.delegate(.openTopic(id)))
                
            case .view(.searchTopicsButtonTapped):
                let userId = state.userId == nil ? state.userSession?.userId : state.userId
                guard let userId else { return .none }
                return .send(.delegate(.openSearch(SearchResult(
                    on: .profile(.topics),
                    author: .id(userId),
                    text: "",
                    sort: .dateDescSort
                ))))
                
            case .view(.searchRepliesButtonTapped):
                let userId = state.userId == nil ? state.userSession?.userId : state.userId
                guard let userId else { return .none }
                return .send(.delegate(.openSearch(SearchResult(
                    on: .profile(.posts),
                    author: .id(userId),
                    text: "",
                    sort: .dateDescSort
                ))))
                
            case let .view(.contextMenu(action)):
                guard let user = state.user else { return .none }
                switch action {
                case .edit:
                    state.destination = .editProfile(EditFeature.State(user: user))
                    return .none
                    
                case .addNotice:
                    state.destination = .note(FormFeature.State(type: .note(userId: user.id)))
                    return .none
                }
                
            case .view(.qmsButtonTapped):
                return .send(.delegate(.openQms))
                
            case .view(.settingsButtonTapped):
                return .send(.delegate(.openSettings))
                
            case .view(.deeplinkTapped(let url, _)):
                return .send(.delegate(.handleUrl(url)))
                
            case .view(.logoutButtonTapped):
                state.destination = .alert(.warning)
                return .none
                
            case .internal(.userResponse(.success(let user))):
                var user = user
                user.devDBdevices.removeAll(where: { $0.name.isEmpty })
                user.devDBdevices.sort(by: { $0.main && !$1.main })
                
                state.user = user
                state.isLoading = false
                reportFullyDisplayed(&state)
                return .none
                
            case .internal(.userResponse(.failure(let error))):
                state.isLoading = false
                print(error, #line)
                reportFullyDisplayed(&state)
                return .none
                
            case let .internal(.updateBadgeCounts(unread)):
                state.qmsBadgeCount = unread.qmsUnreadCount
                state.mentionsBadgeCount = unread.mentionsUnreadCount
                return .none
                
            case let .internal(.updateUserSessionGroup(group)):
                state.userSessionGroup = group
                return .none
                
            case let .destination(.presented(.note(.delegate(.formSent(.note))))):
                return .run { send in
                    await toastClient.showToast(ToastMessage(text: Localization.noteAdded))
                    await send(.view(.onAppear))
                }
                
            case .destination(.presented(.editProfile(.delegate(.profileUpdated(let status))))):
                return .concatenate(
                    .run { _ in
                        await toastClient.showToast(ToastMessage(
                            text: status ? Localization.profileUpdated : Localization.profileUpdateError,
                            haptic: status ? .success : .error
                        ))
                    },
                    .send(.view(.onAppear))
                )
            
            case .destination(.presented(.alert(.logout))):
                state.$userSession.withLock { $0 = nil }
                state.isLoading = true
                return .run { send in
                    try await apiClient.logout()
                }
                
            case .delegate, .binding, .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Analytics()
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}

extension ProfileFeature.Destination.State: Equatable {}

// MARK: - Alert Extension

private extension AlertState where Action == ProfileFeature.Action.Alert {
    nonisolated(unsafe) static let warning = Self {
        TextState("Are you sure you want to log out of your profile ?", bundle: .module)
    } actions: {
        ButtonState(role: .destructive, action: .logout) {
            TextState("Logout", bundle: .module)
        }
        ButtonState(role: .cancel) {
            TextState("Cancel", bundle: .module)
        }
    }
}
