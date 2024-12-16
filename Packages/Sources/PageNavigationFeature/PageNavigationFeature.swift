//
//  PageNavigationFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 11.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import PersistenceKeys
import Models

public enum PageNavigationType {
    case forum
    case topic
    case history
}

@Reducer
public struct PageNavigationFeature: Reducer, Sendable {
    
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        
        let type: PageNavigationType
        public var count: Int = 0
        var offset: Int = 0
        var perPage: Int
        public var shouldShow: Bool {
            return count > perPage
        }
        
        var currentPage: Int {
            return offset / perPage + 1
        }
        
        var totalPages: Int {
            return count / perPage + 1
        }
        
        public init(
            type: PageNavigationType
        ) {
            self.type = type
            
            switch type {
            case .forum: self.perPage = _appSettings.forumPerPage.wrappedValue
            case .topic: self.perPage = _appSettings.topicPerPage.wrappedValue
            case .history: self.perPage = _appSettings.historyPerPage.wrappedValue
            }
        }
    }
    
    public enum Action {
        case firstPageTapped
        case previousPageTapped
        case nextPageTapped
        case lastPageTapped
        
        case offsetChanged(to: Int)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .firstPageTapped:
                state.offset = 0
                
            case .previousPageTapped:
                state.offset -= state.perPage
                
            case .nextPageTapped:
                state.offset += state.perPage
                
            case .lastPageTapped:
                let targetOffset = state.count - (state.count % state.perPage)
                if targetOffset == state.count && state.count > 0 {
                    state.offset = targetOffset - state.perPage
                } else {
                    state.offset = targetOffset
                }
                
            case .offsetChanged:
                return .none
            }
            
            return .run { [offset = state.offset] send in
                await send(.offsetChanged(to: offset))
            }
        }
    }
}
