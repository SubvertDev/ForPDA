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
import PersistenceKeys
import CacheClient

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
        @Shared(.userSession) var userSession: UserSession?
        var userSessionGroup: User.Group?
        
        @Presents public var destination: Destination.State?
        
        let type: ForumStatType
        
        var isLoading = false
        
        public var stat: ForumStat?
        public var topicViewers: TopicViewers?
        
        var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        var isUserHasModerationGroup: Bool {
            return userSessionGroup == .admin
                || userSessionGroup == .supermoderator
                || userSessionGroup == .moderator
        }
        
        var shareLink: String {
            let show = switch type {
            case .forum(let id): "showforum=\(id)"
            case .topic(let topic): "showtopic=\(topic.id)"
            }
            return "https://4pda.to/forum/index.php?\(show)"
        }
        
        public init(
            type: ForumStatType
        ) {
            self.type = type
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
            case loadTopicStat(Topic)
            case loadTopicViewers(Int)
            case loadForumStat(id: Int)
            case forumStatResponse(Result<ForumStat, any Error>)
            case topicViewersResponse(Result<TopicViewers, any Error>)
            
            case updateUserSessionGroup(User.Group)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case userTapped(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.openURL) private var openURL
    @Dependency(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                switch state.type {
                case .forum(let id):
                    return .send(.internal(.loadForumStat(id: id)))
                case .topic(let topic):
                    return .concatenate(
                        .run { [session = state.userSession] send in
                            if let session, let user = cacheClient.getUser(session.userId) {
                                await send(.internal(.updateUserSessionGroup(user.group)))
                            }
                        },
                        .send(.internal(.loadTopicStat(topic)))
                    )
                }
                
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
                
            case let .internal(.loadTopicStat(topic)):
                if state.isUserAuthorized {
                    return .send(.internal(.loadTopicViewers(topic.id)))
                }
                return .none
                
            case let .internal(.loadTopicViewers(topicId)):
                state.isLoading = true
                return .run { send in
                    let response = try await apiClient.getTopicViewers(id: topicId)
                    await send(.internal(.topicViewersResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.topicViewersResponse(.failure(error))))
                }
                
            case let .internal(.topicViewersResponse(.success(response))):
                state.topicViewers = response
                state.isLoading = false
                return .none
                
            case let .internal(.topicViewersResponse(.failure(error))):
                print(error)
                state.isLoading = false
                return .none
                
            case let .internal(.loadForumStat(id)):
                state.isLoading = true
                return .run { send in
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
                
            case let .internal(.updateUserSessionGroup(group)):
                state.userSessionGroup = group
                return .none
                
            case .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension ForumStatFeature.Destination.State: Equatable {}
