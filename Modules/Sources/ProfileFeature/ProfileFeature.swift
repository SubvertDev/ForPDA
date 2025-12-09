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

@Reducer
public struct ProfileFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    private enum Localization {
        static let profileUpdated = LocalizedStringResource("Profile updated", bundle: .module)
        static let profileUpdateError = LocalizedStringResource("Profile update error", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination {
        case alert(AlertState<ProfileFeature.Action.Alert>)
        case editProfile(EditFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        @Shared(.userSession) public var userSession: UserSession?
        public let userId: Int?
        public var isLoading: Bool
        public var user: User?
        
        public var shouldShowToolbarButtons: Bool {
            return userSession != nil && user?.id == userSession?.userId
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
            case editButtonTapped
            case settingsButtonTapped
            case logoutButtonTapped
            case historyButtonTapped
            case reputationButtonTapped
            case deeplinkTapped(URL, ProfileDeeplinkType)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case userResponse(Result<User, any Error>)
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
            case openReputation(Int)
            case handleUrl(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.notificationCenter) private var notificationCenter
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
                return .run { send in
                    for try await user in try await apiClient.getUser(userId, .cacheAndLoad) {
                        await send(.internal(.userResponse(.success(user))))
                    }
                } catch: { error, send in
                    await send(.internal(.userResponse(.failure(error))))
                }
                
            case .view(.historyButtonTapped):
                return .send(.delegate(.openHistory))
                
            case .view(.reputationButtonTapped):
                let userId = state.userId == nil ? state.userSession?.userId : state.userId
                guard let userId else { return .none }
                return .send(.delegate(.openReputation(userId)))
                
            case .view(.editButtonTapped):
                if let user = state.user {
                    state.destination = .editProfile(EditFeature.State(user: user))
                }
                return .none
                
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
