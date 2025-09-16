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
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        let userId: Int
        let username: String
        let content: ReputationChangeRequest.ContentType
        
        var changeReason = ""
        
        public init(
            userId: Int,
            username: String,
            content: ReputationChangeRequest.ContentType
        ) {
            self.userId = userId
            self.username = username
            self.content = content
        }
    }
    
    // MARK: - Action
            
    public enum Action {
        case onAppear
        
        case upButtonTapped
        case downButtonTapped
        case cancelButtonTapped
        
        case reasonChanged(String)
        
        case _sendReputationChange(isDown: Bool)
        case _changeResponse(Result<ReputationChangeResponseType, any Error>)
    }
    
    // MARK: - Dependencies
        
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.dismiss) var dismiss
        
    // MARK: - Body
            
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case .cancelButtonTapped:
                return .run { _ in await dismiss() }
                
            case .upButtonTapped:
                return .send(._sendReputationChange(isDown: false))
                
            case .downButtonTapped:
                return .send(._sendReputationChange(isDown: true))
                
            case .reasonChanged(let reason):
                state.changeReason = reason
                return .none
                
            case ._sendReputationChange(let isDown):
                return .run { [userId = state.userId, content = state.content, reason = state.changeReason] send in
                    let request = ReputationChangeRequest(
                        userId: userId,
                        contentType: content,
                        reason: reason,
                        action: isDown ? .down : .up
                    )
                    let response = try await apiClient.changeReputation(data: request)
                    await send(._changeResponse(.success(response)))
                } catch: { error, send in
                    await send(._changeResponse(.failure(error)))
                }
                
            case let ._changeResponse(.success(status)):
                return .merge([
                    .run { _ in await dismiss() },
                    .run { _ in
                        switch status {
                        case .error:
                            await toastClient.showToast(.reputationChangeError)
                        case .success:
                            await toastClient.showToast(.reputationChanged)
                        case .blocked:
                            await toastClient.showToast(.reputationChangeBlocked)
                        case .selfChangeError:
                            await toastClient.showToast(.reputationSelfChangeError)
                        case .notEnoughtPosts:
                            await toastClient.showToast(.reputationChangeNotEnoughPosts)
                        case .tooLowReputation:
                            await toastClient.showToast(.reputationChangeTooLowReputation)
                        case .cannotChangeToday:
                            await toastClient.showToast(.reputationChangeCannotChangeToday)
                        case .cannotChangeForThisPost:
                            await toastClient.showToast(.reputationChangeCannotChangeForThisPost)
                        case .cannotChangeForThisUserNow:
                            await toastClient.showToast(.reputationChangeCannotChangeForThisUserNow)
                        case .cannotChangeTodayToThisUser:
                            await toastClient.showToast(.reputationChangeCannotChangeTodayForThisUser)
                        case .thisPersonYouRecentlyDownvoted:
                            await toastClient.showToast(.reputationChangeThisPersonYouRecentlyDownvoted)
                        case .thisPersonRecentlyDownvotedYou:
                            await toastClient.showToast(.reputationChangeThisPersonRecentlyDownvotedYou)
                        }
                    }
                ])
                
            case let ._changeResponse(.failure(error)):
                // TODO: handle?
                print("\(error)")
                return .none
            }
        }
    }
}
