//
//  SearchFeature.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 17.08.2025.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct SearchFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field { case authorName }
        
        let searchOn: SearchOn
        let navigation: [ForumInfo]
        
        var focus: Field?
        
        var authorId: Int? = nil
        var searchSort: SearchSort = .relevance
        var whereSearch: SearchWhere = .site
        var forumSearchIn: ForumSearchIn = .all
        
        var searchText = ""
        var authorName = ""
        var isAuthorsLoading = false
        var shouldShowAuthorsList = false
        var searchResultsAsTopics = false
        var authors: [SearchUsersResponse.SimplifiedUser] = []
        
        public init(
            on: SearchOn = .site,
            navigation: [ForumInfo] = [.mock]
        ) {
            self.searchOn = on
            self.navigation = navigation
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            case startSearch
            case searchAuthorName(String)
            case selectUser(Int, String)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case search(SearchOn)
            case searchUsersResponse(SearchUsersResponse)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                switch state.searchOn {
                case .site:
                    state.whereSearch = .site
                case .topic:
                    state.whereSearch = .topic
                case .forum(_, let sIn, let asTopics):
                    state.forumSearchIn = sIn
                    state.searchResultsAsTopics = asTopics
                }
                return .none
                
            case .view(.startSearch):
                let searchOn: SearchOn = switch state.whereSearch {
                case .site:  .site
                case .topic: state.searchOn
                case .forum:
                    if case .forum(let id, _, _) = state.searchOn {
                        .forum(id: id, sIn: state.forumSearchIn, asTopics: state.searchResultsAsTopics)
                    } else {
                        .forum(id: nil, sIn: state.forumSearchIn, asTopics: state.searchResultsAsTopics)
                    }
                case .custom:
                    if let info = state.navigation.last, !info.isCategory {
                        .forum(id: info.id, sIn: state.forumSearchIn, asTopics: state.searchResultsAsTopics)
                    } else {
                        fatalError("Unexpected case. Info: [\(state.navigation)]")
                    }
                }
                return .send(.internal(.search(searchOn)))
                
            case let .view(.searchAuthorName(nickname)):
                state.isAuthorsLoading = true
                return .run { send in
                    let request = SearchUsersRequest(term: nickname, offset: 0, number: 12)
                    let result = try await apiClient.searchUsers(request: request)
                    await send(.internal(.searchUsersResponse(result)))
                }
                
            case let .view(.selectUser(id, name)):
                state.authorId = id
                state.authorName = name
                state.shouldShowAuthorsList = false
                return .none
                
            case let .internal(.search(searchOn)):
                return .run { [
                    authorId = state.authorId,
                    text = state.searchText,
                    sort = state.searchSort
                ] send in
                    let request = SearchRequest(
                        on: searchOn,
                        authorId: authorId,
                        text: text,
                        sort: sort,
                        offset: 0,
                        amount: 10
                    )
                    let result = try await apiClient.search(request: request)
                    customDump(result)
                }
                
            case let .internal(.searchUsersResponse(data)):
                state.authors = data.users
                state.isAuthorsLoading = false
                state.shouldShowAuthorsList = data.usersCount > 0
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
