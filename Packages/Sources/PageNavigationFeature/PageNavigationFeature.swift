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
}

@Reducer
public struct PageNavigationFeature: Sendable {
    
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        let type: PageNavigationType
        public var count: Int = 0
        var offset: Int = 0
        var perPage: Int
        
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
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .firstPageTapped:
                state.offset = 0
                
            case .previousPageTapped:
                state.offset -= state.perPage
                
            case .nextPageTapped:
                state.offset += state.perPage
                
            case .lastPageTapped:
                state.offset = state.count - (state.count % state.perPage)
                
            case .offsetChanged:
                return .none
            }
            
            return .run { [offset = state.offset] send in
                await send(.offsetChanged(to: offset))
            }
        }
    }
}
