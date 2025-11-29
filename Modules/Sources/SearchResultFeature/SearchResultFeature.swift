//
//  SearchResultFeature.swift
//  ForPDA
//
//  Created by Xialtal on 26.11.25.
//

import Foundation
import ComposableArchitecture
import Models
import PersistenceKeys
import SharedUI

@Reducer
public struct SearchResultFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.userSession) var userSession: UserSession?
        
        public let response: SearchResponse
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        public init(
            response: SearchResponse
        ) {
            self.response = response
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            
            case postTapped
            case topicTapped
            case articleTapped
        }
        
        case `internal`(Internal)
        public enum `Internal` {
            case loadPostTypes([UITopicType])
        }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .none
                
            case .view(.postTapped):
                return .none
                
            case .view(.topicTapped):
                return .none
                
            case .view(.articleTapped):
                return .none
                
            case .internal(.loadPostTypes(let types)):
                return .none
            }
        }
    }
}
