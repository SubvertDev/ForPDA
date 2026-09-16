//
//  ReputationChangeFeature.swift
//  ForPDA
//
//  Created by Xialtal on 13.06.25.
//

import Foundation
import ComposableArchitecture
import TCAExtensions
import APIClient
import ToastClient
import Models

@Reducer
public struct ReputationChangeFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    public enum Localization {
        static let reputationChanged = LocalizedStringResource("Reputation changed", bundle: .module)
        static let reputationChangeError = LocalizedStringResource("Reputation change error", bundle: .module)
        static let reputationChangeBlocked = LocalizedStringResource("Reputation change blocked", bundle: .module)
        static let reputationSelfChangeError = LocalizedStringResource("Cannot change self reputation", bundle: .module)
        static let reputationChangeNotEnoughPosts = LocalizedStringResource("Not enough posts for reputation change", bundle: .module)
        static let reputationChangeTooLowReputation = LocalizedStringResource("Your reputation is too low", bundle: .module)
        static let reputationChangeCannotChangeToday = LocalizedStringResource(
            "You can no longer change reputation today", bundle: .module)
        static let reputationChangeCannotChangeForThisPost = LocalizedStringResource(
            "You can not change reputation for this post", bundle: .module)
        static let reputationChangeCannotChangeForThisUserNow = LocalizedStringResource(
            "You can not change reputation for this user now", bundle: .module)
        static let reputationChangeCannotChangeTodayForThisUser = LocalizedStringResource(
            "You can not change reputation for this user today", bundle: .module)
        static let reputationChangeThisPersonYouRecentlyDownvoted = LocalizedStringResource(
            "Change denied, this person you recently downvoted", bundle: .module)
        static let reputationChangeThisPersonRecentlyDownvotedYou = LocalizedStringResource(
            "Change denied, this person recently downvoted you", bundle: .module)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field { case reason }
        
        var focus: Field? = .reason
        
        let userId: Int
        let action: ReputationChangeActionType?
        let username: String
        let content: ReputationChangeContentType
        
        var changeReason: String
        
        public init(
            userId: Int,
            action: ReputationChangeActionType? = nil,
            username: String = "",
            content: ReputationChangeContentType,
            message: String = "",
        ) {
            self.userId = userId
            self.action = action
            self.username = username
            self.content = content
            self.changeReason = message
        }
    }
    
    // MARK: - Action
            
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case reasonChanged(String)
        
        case view(View)
        public enum View {
            case onAppear
            
            case upButtonTapped
            case downButtonTapped
            case cancelButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case sendReputationChange(isDown: Bool)
            case changeResponse(Result<ReputationChangeResponseType, any Error>)
        }
    }
    
    // MARK: - Dependencies
        
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.dismiss) var dismiss
        
    // MARK: - Body
            
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .reasonChanged(let reason):
                state.changeReason = reason
                return .none
                
            case .view(.onAppear), .binding:
                return .none
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.upButtonTapped):
                return .send(.internal(.sendReputationChange(isDown: false)))
                
            case .view(.downButtonTapped):
                return .send(.internal(.sendReputationChange(isDown: true)))
                
            case let .internal(.sendReputationChange(isDown)):
                return .run { [userId = state.userId, content = state.content, reason = state.changeReason] send in
                    let request = ReputationChangeRequest(
                        userId: userId,
                        contentType: content,
                        reason: reason,
                        action: isDown ? .down : .up
                    )
                    let response = try await apiClient.changeReputation(data: request)
                    await send(.internal(.changeResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.changeResponse(.failure(error))))
                }
                
            case let .internal(.changeResponse(.success(status))):
                return .merge([
                    .run { _ in await dismiss() },
                    .run { _ in
                        let toast = ToastMessage(
                            text: reputationStatusToText(status),
                            isError: status == .success ? false : true,
                            haptic: status == .success ? .success : .error
                        )
                        await toastClient.showToast(toast)
                    }
                ])
                
            case let .internal(.changeResponse(.failure(error))):
                // TODO: handle?
                print("\(error)")
                return .none
            }
        }
    }
    
    // MARK: - Helpers
    
    private func reputationStatusToText(_ status: ReputationChangeResponseType) -> LocalizedStringResource {
        switch status {
        case .error:
            return Localization.reputationChangeError
        case .success:
            return Localization.reputationChanged
        case .blocked:
            return Localization.reputationChangeBlocked
        case .selfChangeError:
            return Localization.reputationSelfChangeError
        case .notEnoughtPosts:
            return Localization.reputationChangeNotEnoughPosts
        case .tooLowReputation:
            return Localization.reputationChangeTooLowReputation
        case .cannotChangeToday:
            return Localization.reputationChangeCannotChangeToday
        case .cannotChangeForThisPost:
            return Localization.reputationChangeCannotChangeForThisPost
        case .cannotChangeForThisUserNow:
            return Localization.reputationChangeCannotChangeForThisUserNow
        case .cannotChangeTodayToThisUser:
            return Localization.reputationChangeCannotChangeTodayForThisUser
        case .thisPersonYouRecentlyDownvoted:
            return Localization.reputationChangeThisPersonYouRecentlyDownvoted
        case .thisPersonRecentlyDownvotedYou:
            return Localization.reputationChangeThisPersonRecentlyDownvotedYou
        }
    }
}
