//
//  ReputationFeature.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 11.07.2025.
//

import Foundation
import ComposableArchitecture
import APIClient

@Reducer
public struct ReputationFeature: Reducer, Sendable {
    
    public init() {}
    
    enum PickerSelection: Int {
        case history = 1
        case votes = 2
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        
        public var isLoading = false
        var pickerSelection: PickerSelection = .history
        
        public init() {}
        
    }
    
    // MARK: - Action
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadHistory
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    public var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> {state, action in
            switch action {
            case .view(.onAppear):
                if state.pickerSelection == .history {
                    print("is onAppear history")
                    
                } else {
                    print("is onappear votes")
                }
            return .none
                
            case .internal(.loadHistory):
                
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
