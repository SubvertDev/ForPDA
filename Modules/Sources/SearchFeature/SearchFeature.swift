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
        var searchText = ""
        var toggleRes = false
        var nicknameAuthor = ""
        var authorId: Int? = nil
        var whereSearch = "Everywhere"
        var sortBy = "Relevance(matching the query)"
        var whereSerchForum = "Everywhere"
        var showMembers = false
        var members: [Member] = []
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            case startSearch
            case additionalHidenToggle
            case searchAuthorName(String)
            case selectUser(Int, String)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case search(SearchRequest)
            case addMembers(MembersResponse)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
                
            case .view(.startSearch):
                return .send(.internal(.search(formatData(
                    searchText: state.searchText,
                    isTopicFormat: state.toggleRes,
                    nicknameAuthor: state.nicknameAuthor,
                    authorId: state.authorId,
                    whereSearch: state.whereSearch,
                    whereSearchForum: state.whereSerchForum,
                    sortBy: state.sortBy
                ))))
                
            case let .view(.searchAuthorName(nickname)):
                return .run { send in
                    let request = MembersRequest(term: nickname, offset: 10, number: 3)
                    let result = try await apiClient.members(request: request)
                    await send(.internal(.addMembers(result)))
                }
                
            case let .view(.selectUser(id, nickname)):
                state.nicknameAuthor = nickname
                state.authorId = id
                state.showMembers = false
                return .none
                
            case let .internal(.search(request)):
                return .run { send in
                    let result = try await apiClient.startSearch(request: request)
                    print(result.publications)
                }
                
            case let .internal(.addMembers(data)):
                state.members = data.members
                print("from internal  = \(state.members)")
                state.showMembers = !data.members.isEmpty
                print("from internal  = \(state.showMembers)")
                return .none
                
            case .binding:
                return .none
                
            default:
                return .none
            }
        }
    }
    
    private func formatData(
        searchText: String,
        isTopicFormat: Bool,
        nicknameAuthor: String,
        authorId: Int?,
        whereSearch: String,
        whereSearchForum: String,
        sortBy: String
    ) -> SearchRequest {
        
        let searchIn: SearchRequest.ForumSearchIn
        let searchOn: SearchRequest.SearchOn
        
        switch whereSearchForum {
        case "Everywhere":
            searchIn = .all
        case "In topic titles only":
            searchIn = .titles
        case "Only in messages":
            searchIn = .posts
        default:
            searchIn = .all
        }
        
        switch whereSearch {
        case "Everywhere":
            searchOn = .site
        case "On the forum":
            searchOn = .forum(id: nil, sIn: searchIn, asTopics: isTopicFormat)
        case "On the site":
            searchOn = .site
        default:
            searchOn = .site
        }
        
        let sort: SearchRequest.SearchSort
        switch sortBy {
        case "Relevance(matching the query)":
            sort = .relevance
        case "Date (newest to oldest)":
            sort = .dateAscSort
        case "Date (oldest to newest)":
            sort = .dateDescSort
        default:
            sort = .relevance
        }
        
        return SearchRequest(on: searchOn, authorId: authorId, text: searchText, sort: sort, offset: 10)
    }
}
