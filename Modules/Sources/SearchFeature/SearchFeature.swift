//
//  SearchFeature.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 17.08.2025.
//

import Foundation
import ComposableArchitecture
import APIClient

@Reducer
public struct SearchFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        
        public init() {}
        
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        
        case view(View)
        public enum View {
            case onAppear
        }
        
        case `internal`(Internal)
        public enum Internal {
            case search(String)
        }
        
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .internal(.search(word)):
                return .run { send in
                    let request = SearchRequest(
                        on: .forum(
                            id: nil,
                            sIn: .all,
                            asTopics: false
                        ),
                        authorId: nil,
                        text: word,
                        sort: .relevance,
                        offset: 10
                    )
                    
                    let result = try await apiClient.startSearch(request: request)
                    print(result.publications)
                }
                
                
                
            default:
                return .none
            }
        }
    }
}
