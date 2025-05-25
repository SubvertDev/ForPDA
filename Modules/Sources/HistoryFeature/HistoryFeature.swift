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
    
    public enum Action {
        case onTask
        case topicTapped(id: Int)
        
        case pageNavigation(PageNavigationFeature.Action)
        
        case _historyResponse(Result<History, any Error>)
        case _loadHistory(offset: Int)
        
        case delegate(Delegate)
        public enum Delegate {
            case openTopic(id: Int)
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
            case .onTask:
                return .send(._loadHistory(offset: state.offset))
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                state.offset = newOffset
                return .send(._loadHistory(offset: newOffset))
                
            case .pageNavigation:
                return .none
                
            case let .topicTapped(id: id):
                return .send(.delegate(.openTopic(id: id)))
                
            case let ._loadHistory(offset):
                state.isLoading = true
                return .run { [perPage = state.appSettings.forumPerPage] send in
                    let result = await Result {
                        try await apiClient.getHistory(offset, perPage)
                    }
                    await send(._historyResponse(result))
                }
                
            case let ._historyResponse(.success(response)):
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
                
            case let ._historyResponse(.failure(error)):
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
