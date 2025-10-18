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
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field: Sendable { case page }
        
        @Shared(.appSettings) var appSettings: AppSettings
        
        let type: PageNavigationType
        public var page = "1"
        public var count = 0
        public var offset = 0
        var perPage: Int
        public var focus: Field?
        public var shouldShow: Bool {
            return count > perPage
        }
        
        var currentPage: Int {
            return Int(ceil(Double(offset) / Double(perPage))) + 1
        }
        
        var totalPages: Int {
            return Int(ceil(Double(count) / Double(perPage)))
        }
        
        public var isLastPage: Bool {
            return currentPage == totalPages
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
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case firstPageTapped
        case previousPageTapped
        case nextPageTapped
        case lastPageTapped
        case doneButtonTapped
        case onViewTapped
        case goToPage(newPage: Int)
        
        case update(count: Int, offset: Int?)
        case offsetChanged(to: Int)
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.focus):
                state.page = String(state.currentPage)
                return .none
                
            case .binding:
                return .none
                
            case .doneButtonTapped:
                state.focus = nil
                guard let newPage = Int(state.page) else {
                    state.page = String(state.currentPage)
                    return .none
                }
                guard newPage != state.currentPage else {
                    return .none
                }
                return .send(.goToPage(newPage: newPage))
                
            case .goToPage(let newPage):
                state.offset = (newPage - 1) * state.perPage
                state.page = String(state.currentPage)
                
            case .onViewTapped:
                state.focus = state.focus == nil ? .page : nil
                return .none
                
            case .firstPageTapped:
                state.offset = 0
                state.page = String(state.currentPage)
                
            case .previousPageTapped:
                state.offset -= state.perPage
                state.page = String(state.currentPage)
                
            case .nextPageTapped:
                state.offset += state.perPage
                state.page = String(state.currentPage)
                
            case .lastPageTapped:
                let targetOffset = state.count - (state.count % state.perPage)
                if targetOffset == state.count && state.count > 0 {
                    state.offset = targetOffset - state.perPage
                } else {
                    state.offset = targetOffset
                }
                state.page = String(state.currentPage)
                
            case let .update(count: count, offset: offset):
                state.count = count
                if let offset { state.offset = offset }
                state.page = String(state.currentPage)
                return .none
                
            case .offsetChanged:
                return .none
            }
            
            return .run { [offset = state.offset] send in
                await send(.offsetChanged(to: offset))
            }
        }
    }
}
