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
        public var pageText: String = "1"
        public var textWidth: CGFloat = 30
        public var count: Int = 0
        public var offset: Int = 0
        var perPage: Int
        public var isFocused: Bool = false
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
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case firstPageTapped
        case previousPageTapped
        case nextPageTapped
        case lastPageTapped
        case doneButtonTapped
        case updateWidth(geometry: GeometryProxy)
        case updatePageText(value: String)
        case setFocus(focusState: Bool)
        
        case update(count: Int, offset: Int?)
        case offsetChanged(to: Int)
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
                
            case .doneButtonTapped:
                if state.pageText.isEmpty {
                    state.offset = 0
                    state.pageText = "1"
                } else {
                    let currentPage = Int(state.pageText) ?? 1
                    state.offset = (currentPage - 1) * state.perPage
                }
                
                
            case .setFocus(let focusState):
                state.isFocused = focusState
                return .none
                
            case .updateWidth(let geometry):
                let newWidth = max(30, geometry.size.width + 15)
                if newWidth != state.textWidth {
                    state.textWidth = newWidth
                }
                return .none
                
            case .updatePageText(let newValue):
                state.pageText = newValue
                return .none
                
            case .firstPageTapped:
                state.offset = 0
                state.pageText = "1"
                
            case .previousPageTapped:
                state.offset -= state.perPage
                state.pageText = "\(state.currentPage)"
                
            case .nextPageTapped:
                state.offset += state.perPage
                state.pageText = "\(state.currentPage)"
                
            case .lastPageTapped:
                let targetOffset = state.count - (state.count % state.perPage)
                if targetOffset == state.count && state.count > 0 {
                    state.offset = targetOffset - state.perPage
                } else {
                    state.offset = targetOffset
                }
                state.pageText = "\(state.currentPage)"
                
            case let .update(count: count, offset: offset):
                state.count = count
                if let offset { state.offset = offset }
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
