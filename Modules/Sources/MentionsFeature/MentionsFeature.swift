//
//  MentionsFeature.swift
//  ForPDA
//
//  Created by Codex on 19.02.2026.
//

import Foundation
import ComposableArchitecture
import PageNavigationFeature
import APIClient
import Models
import AnalyticsClient
import NotificationsClient

@Reducer
public struct MentionsFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        
        public var mentions: [Mention] = []
        public var isLoading = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .mentions)
        
        var offset = 0
        var didLoadOnce = false
        
        public init(
            mentions: [Mention] = []
        ) {
            self.mentions = mentions
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case pageNavigation(PageNavigationFeature.Action)
        
        case view(View)
        public enum View {
            case onAppear
            case mentionTapped(Mention)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadMentions(offset: Int)
            case mentionsResponse(Result<Mentions, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openTopic(id: Int, name: String, goTo: GoTo)
            case openArticle(sourceId: Int, targetId: Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.notificationsClient) private var notificationsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadMentions(offset: state.offset)))
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                state.offset = newOffset
                return .send(.internal(.loadMentions(offset: newOffset)))
                
            case .pageNavigation:
                return .none
                
            case let .view(.mentionTapped(mention)):
                switch mention.type {
                case .article:
                    return .send(.delegate(.openArticle(sourceId: mention.sourceId, targetId: mention.targetId)))
                case .topic:
                    return .send(.delegate(.openTopic(id: mention.sourceId, name: mention.sourceName, goTo: .post(id: mention.targetId))))
                }
                
            case let .internal(.loadMentions(offset)):
                state.isLoading = true
                return .run { [perPage = state.appSettings.mentionsPerPage] send in
                    let result = await Result {
                        try await apiClient.getMentions(false, offset, perPage)
                    }
                    await send(.internal(.mentionsResponse(result)))
                }
                
            case let .internal(.mentionsResponse(.success(response))):
                state.mentions = response.mentions
                state.pageNavigation.count = response.mentionsCount
                state.isLoading = false
                reportFullyDisplayed(&state)
                return .run { _ in
                    await notificationsClient.removeNotifications(categories: [.forumMention, .siteMention])
                    let unread = try await apiClient.getUnread(type: .all)
                    await notificationsClient.showUnreadNotifications(unread, skipCategories: [])
                }
                
            case let .internal(.mentionsResponse(.failure(error))):
                print(error)
                state.isLoading = false
                reportFullyDisplayed(&state)
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}
