//
//  ForumStatFeature.swift
//  ForPDA
//
//  Created by Xialtal on 14.06.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct ForumStatFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination: Hashable {
        @ReducerCaseIgnored
        case share(URL)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        
        let forumId: Int
        
        var isLoading = false
        
        public var stat: ForumStat?
        
        public var shareLink: String {
            return "https://4pda.to/forum/index.php?showforum=\(forumId)"
        }
        
        public init(
            forumId: Int
        ) {
            self.forumId = forumId
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            
            case linkShared
            case userButtonTapped(Int)
            
            case closeButtonTapped
            case shareLinkButtonTapped
            case openInBrowserButtonTapped
        }
        
        case destination(PresentationAction<Destination.Action>)
        
        case `internal`(Internal)
        public enum Internal {
            case loadForumStat
            case forumStatResponse(Result<ForumStat, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case userTapped(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.openURL) var openURL
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadForumStat))
                
            case .view(.closeButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.linkShared):
                state.destination = nil
                return .none
                
            case let .view(.userButtonTapped(id)):
                return .run { send in
                    await send(.delegate(.userTapped(id)))
                    await dismiss()
                }
                
            case .view(.shareLinkButtonTapped):
                state.destination = .share(URL(string: state.shareLink)!)
                return .none
                
            case .view(.openInBrowserButtonTapped):
                return .run { [shareLink = state.shareLink] _ in
                    await openURL(URL(string: shareLink)!)
                }
                
            case .internal(.loadForumStat):
                state.isLoading = true
                return .run { [id = state.forumId] send in
                    let response = try await apiClient.getForumStat(id)
                    await send(.internal(.forumStatResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.forumStatResponse(.failure(error))))
                }
                
            case let .internal(.forumStatResponse(.success(response))):
                state.stat = response
                state.isLoading = false
                return .none
                
            case let .internal(.forumStatResponse(.failure(error))):
                print(error)
                return .none
                
            case .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension ForumStatFeature.Destination.State: Equatable {}
