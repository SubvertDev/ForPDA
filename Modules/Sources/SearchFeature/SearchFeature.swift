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
            
            case cancelButtonTapped
            case authorProfileButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case searchUsersResponse(SearchUsersResponse)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case userProfileTapped(Int)
            case searchOptionsConstructed(SearchResult)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.authorName):
                if !state.authorName.isEmpty, state.authorName.count >= 3 {
                    return .send(.view(.searchAuthorName(state.authorName)))
                }
                return .none
                
            case .view(.onAppear):
                switch state.searchOn {
                case .site:
                    state.whereSearch = .site
                case .topic:
                    state.whereSearch = .topic
                case .forum(_, let sIn, let asTopics):
                    state.whereSearch = !state.navigation.isEmpty ? .forumById : .forum
                    state.forumSearchIn = sIn
                    state.searchResultsAsTopics = asTopics
                }
                return .none
            
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case .delegate(.userProfileTapped),
                 .delegate(.searchOptionsConstructed):
                return .run { _ in await dismiss() }
                
            case .view(.authorProfileButtonTapped):
                return .send(.delegate(.userProfileTapped(state.authorId!)))
                
            case let .view(.searchAuthorName(nickname)):
                state.authorId = nil
                state.isAuthorsLoading = true
                state.shouldShowAuthorsList = false
                return .run { send in
                    let request = SearchUsersRequest(term: nickname, offset: 0, number: 12)
                    let result = try await apiClient.searchUsers(request: request)
                    await send(.internal(.searchUsersResponse(result)))
                }
                
            case let .view(.selectUser(id, name)):
                state.authorName = name
                state.authorId = id
                state.shouldShowAuthorsList = false
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
                case .forumById:
                    if let forum = state.navigation.last, !forum.isCategory {
                        .forum(id: forum.id, sIn: state.forumSearchIn, asTopics: state.searchResultsAsTopics)
                    } else {
                        fatalError("Unexpected case. Info: [\(state.navigation)]")
                    }
                }
                return .send(.delegate(.searchOptionsConstructed(SearchResult(
                    on: searchOn,
                    authorId: state.authorId,
                    text: state.searchText,
                    sort: state.searchSort
                ))))
                
            case let .internal(.searchUsersResponse(data)):
                state.authors = data.users
                state.isAuthorsLoading = false
                state.shouldShowAuthorsList = data.usersCount > 0
                return .none
                
            case .binding, .delegate:
                return .none
            }
        }
    }
}
