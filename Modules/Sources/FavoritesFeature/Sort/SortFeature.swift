//
//  SortFeature.swift
//  ForPDA
//
//  Created by Xialtal on 1.01.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct SortFeature: Reducer, Sendable {
    
    public init() {}
        
    // MARK: - State
        
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        
        var sortType: SortType
        public var isReverseOrder: Bool
        public var isUnreadFirst: Bool
        
        public init() {
            self.sortType = _appSettings.favorites.isSortByName.wrappedValue ? .byName : .byDate
            self.isReverseOrder = _appSettings.favorites.isReverseOrder.wrappedValue
            self.isUnreadFirst = _appSettings.favorites.isUnreadFirst.wrappedValue
        }
    }
    
    // MARK: - Action
            
    public enum Action: BindableAction {
        case onAppear
        
        case saveButtonTapped
        case cancelButtonTapped
        
        case binding(BindingAction<State>)
    }
    
    // MARK: - Dependencies
        
    @Dependency(\.apiClient) private var apiClient
        
    // MARK: - Body
            
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear, .binding, .cancelButtonTapped:
                return .none
                
            case .saveButtonTapped:
                state.$appSettings.favorites.isReverseOrder.withLock { $0 = state.isReverseOrder }
                state.$appSettings.favorites.isUnreadFirst.withLock { $0 = state.isUnreadFirst }
                state.$appSettings.favorites.isSortByName.withLock { [sort = state.sortType] in
                    $0 = sort == .byName ? true : false
                }
                return .none
            }
        }
    }
}
