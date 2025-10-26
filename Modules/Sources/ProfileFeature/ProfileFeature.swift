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

@Reducer
public struct ProfileFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination {
        case alert(AlertState<ProfileFeature.Action.Alert>)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        @Shared(.userSession) public var userSession: UserSession?
        @Shared(.appStorage("didAcceptQMSWarningMessage")) var didAcceptQMSWarningMessage = false
        public let userId: Int?
        public var isLoading: Bool
        public var user: User?
        
        public var shouldShowToolbarButtons: Bool {
            return userSession != nil && user?.id == userSession?.userId
        }
        
        var didLoadOnce = false
        
        public var showQMSWarningSheet: Bool
        
        public init(
            userId: Int? = nil,
            isLoading: Bool = true,
            user: User? = nil,
            showQMSWarningSheet: Bool = false
        ) {
            self.userId = userId
            self.isLoading = isLoading
            self.user = user
            self.showQMSWarningSheet = showQMSWarningSheet
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
            case reputationButtonTapped
            case deeplinkTapped(URL, ProfileDeeplinkType)
            case sheetContinueButtonTapped
            case sheetCloseButtonTapped
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
                
            case .view(.qmsButtonTapped):
                if state.didAcceptQMSWarningMessage {
                    return .send(.delegate(.openQms))
                } else {
                    state.showQMSWarningSheet = true
                    return .none
                }
                
            case .view(.sheetContinueButtonTapped):
                state.$didAcceptQMSWarningMessage.withLock { $0 = true }
                state.showQMSWarningSheet = false
                return .send(.delegate(.openQms))
                
            case .view(.sheetCloseButtonTapped):
                state.showQMSWarningSheet = false
                return .none
                
            case .view(.settingsButtonTapped):
                return .send(.delegate(.openSettings))
                
            case .view(.deeplinkTapped(let url, _)):
                return .send(.delegate(.handleUrl(url)))
                
            case .view(.logoutButtonTapped):
                state.destination = .alert(.warning)
                return .none
                
            case .internal(.userResponse(.success(let user))):
                state.isLoading = false
                state.user = user
                reportFullyDisplayed(&state)
                return .none
                
            case .internal(.userResponse(.failure(let error))):
                state.isLoading = false
                print(error, #line)
                reportFullyDisplayed(&state)
                return .none
                
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
