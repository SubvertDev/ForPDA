//
//  HistoryFeature.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import Foundation
import ComposableArchitecture
import PageNavigationFeature
import APIClient
import Models
import AnalyticsClient

@Reducer
public struct HistoryFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        
        public var history: [HistoryRow] = []
        public var isLoading = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .history)
        
        var offset = 0
        var didLoadOnce = false
        
        public init(
            history: [HistoryRow] = []
        ) {
            self.history = history
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case pageNavigation(PageNavigationFeature.Action)

        case view(View)
        public enum View {
            case onAppear
            case topicTapped(TopicInfo, showUnread: Bool)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case historyResponse(Result<History, any Error>)
            case loadHistory(offset: Int)
        }

        case delegate(Delegate)
        public enum Delegate {
            case openTopic(id: Int, name: String, goTo: GoTo)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadHistory(offset: state.offset)))
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                state.offset = newOffset
                return .send(.internal(.loadHistory(offset: newOffset)))
                
            case .pageNavigation:
                return .none
                
            case let .view(.topicTapped(topic, showUnread)):
                guard !showUnread else {
                    return .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: .unread)))
                }
                let goTo = state.appSettings.topicOpeningStrategy.asGoTo
                return .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: goTo)))
                
            case let .internal(.loadHistory(offset)):
                state.isLoading = true
                return .run { [perPage = state.appSettings.forumPerPage] send in
                    let result = await Result {
                        try await apiClient.getHistory(offset, perPage)
                    }
                    await send(.internal(.historyResponse(result)))
                }
                
            case let .internal(.historyResponse(.success(response))):
                var groupedHistories: [Date: [TopicInfo]] = [:]
                
                let calendar = Calendar.current
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                for history in response.histories {
                    let dateWithoutTime = calendar.startOfDay(for: history.seenDate)
                    
                    if groupedHistories[dateWithoutTime] != nil {
                        groupedHistories[dateWithoutTime]?.append(history.topic)
                    } else {
                        groupedHistories[dateWithoutTime] = [history.topic]
                    }
                }
                
                var sortedHistories: [HistoryRow] = []
                for (date, topics) in groupedHistories {
                    sortedHistories.append(HistoryRow(seenDate: date, topics: topics))
                }

                sortedHistories.sort { $0.seenDate > $1.seenDate }
                
                state.history = sortedHistories
                
                // TODO: Is it ok?
                state.pageNavigation.count = response.historiesCount
                
                state.isLoading = false
                reportFullyDisplayed(&state)
                return .none
                
            case let .internal(.historyResponse(.failure(error))):
                // TODO: Handle error
                print(error)
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
