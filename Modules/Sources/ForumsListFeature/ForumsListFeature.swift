//
//  ForumFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.09.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import AnalyticsClient
import SearchFeature

@Reducer
public struct ForumsListFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        case search(SearchFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        
        public var forums: [ForumRowInfo]?
        public var isExpanded: [Int: Bool] = [:]
        var didLoadOnce = false
        
        public init(
            forums: [ForumRowInfo]? = nil
        ) {
            self.forums = forums
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case destination(PresentationAction<Destination.Action>)
        
        case view(View)
        public enum View {
            case onAppear
            case searchButtonTapped
            case forumRedirectTapped(URL)
            case forumTapped(id: Int, name: String)
            case forumSectionExpandTapped(Int)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case forumsListResponse(Result<[ForumInfo], any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openSearch(SearchResult)
            case openForum(id: Int, name: String)
            case openUserProfile(id: Int)
            case handleForumRedirect(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                guard state.forums == nil else { return .none }
                return .run { send in
                    for try await forumList in try await apiClient.getForumsList(policy: .cacheOrLoad) {
                        await send(.internal(.forumsListResponse(.success(forumList))))
                    }
                } catch: { error, send in
                    await send(.internal(.forumsListResponse(.failure(error))))
                }
                
            case .view(.searchButtonTapped):
                state.destination = .search(SearchFeature.State(
                    on: .forum(id: nil, sIn: .all, asTopics: false)
                ))
                return .none
                
            case let .destination(.presented(.search(.delegate(.userProfileTapped(id))))):
                return .send(.delegate(.openUserProfile(id: id)))
                
            case let .destination(.presented(.search(.delegate(.searchOptionsConstructed(options))))):
                return .send(.delegate(.openSearch(options)))
                
            case let .view(.forumTapped(id: id, name: name)):
                return .send(.delegate(.openForum(id: id, name: name)))
                
            case let .view(.forumRedirectTapped(url)):
                return .send(.delegate(.handleForumRedirect(url)))
                
            case let .view(.forumSectionExpandTapped(id)):
                state.isExpanded[id]?.toggle()
                return .none
                
            case let .internal(.forumsListResponse(.success(forums))):
                var rows: [ForumRowInfo] = []
                
                for forum in forums {
                    if forum.isCategory {
                        let category = ForumRowInfo(id: forum.id, title: forum.name, forums: [])
                        rows.append(category)
                        state.isExpanded[forum.id] = true
                    } else {
                        rows[rows.count - 1].forums.append(forum)
                    }
                }
                
                state.forums = rows
                reportFullyDisplayed(&state)
                
            case let .internal(.forumsListResponse(.failure(error))):
                print(error)
                // TODO: Add toast
                reportFullyDisplayed(&state)
                
            case .delegate, .destination:
                break
            }
            
            return .none
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

extension ForumsListFeature.Destination.State: Equatable {}
