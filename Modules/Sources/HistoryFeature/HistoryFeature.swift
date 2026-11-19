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
        public var isRefreshing = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .history)
        
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
            case onFirstAppear
            case onRefresh
            
            case topicTapped(TopicInfo, showUnread: Bool)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case refresh
            case loadHistory(offset: Int)
            case historyResponse(Result<History, any Error>)
            
            case markRead(topic: TopicInfo)
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
        Scope(\.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(.internal(.loadHistory(offset: newOffset)))
                
            case .pageNavigation, .delegate:
                return .none
                
            case .view(.onFirstAppear):
                return .send(.internal(.loadHistory(offset: 0)))
                
            case .view(.onRefresh):
                guard !state.isLoading else { return .none }
                return .send(.internal(.refresh))
                
            case let .view(.topicTapped(topic, showUnread)):
                return .run { [goTo = state.appSettings.topicOpeningStrategy.asGoTo] send in
                    await send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: showUnread ? .unread : goTo)))
                    if topic.isUnread { await send(.internal(.markRead(topic: topic))) }
                }
                
            case .internal(.refresh):
                state.isRefreshing = true
                return .send(.internal(.loadHistory(offset: state.pageNavigation.offset)))
                
            case let .internal(.loadHistory(offset)):
                if !state.isRefreshing {
                    state.isLoading = true
                }
                return .run { [perPage = state.appSettings.historyPerPage] send in
                    let response = try await apiClient.getHistory(offset, perPage)
                    await send(.internal(.historyResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.historyResponse(.failure(error))))
                }
                
            case let .internal(.historyResponse(.success(response))):
                var groupedHistories: [Date: [TopicInfo]] = [:]
                
                for history in response.histories {
                    let dateWithoutTime = Calendar.current.startOfDay(for: history.seenDate)
                    
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
                state.isRefreshing = false
                analyticsClient.reportFullyDisplayed()
                return .none
                
            case let .internal(.historyResponse(.failure(error))):
                // TODO: Handle error
                print(error)
                analyticsClient.reportFullyDisplayed()
                return .none
                
            case let .internal(.markRead(topic)):
                guard let rowIndex = state.history.firstIndex(where: { $0.topics.contains(topic) }),
                      let topicIndex = state.history[rowIndex].topics.firstIndex(of: topic) else {
                    return .none
                }
                state.history[rowIndex].topics[topicIndex].flag.remove(.updated)
                return .none
            }
        }
        
        Analytics()
    }
    
    // MARK: - Shared Logic
    }
