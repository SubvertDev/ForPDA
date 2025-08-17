//
//  SearchFeature.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 17.08.2025.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct SearchFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        
        case view(View)
        public enum View {
            case onAppear
        }
        
    }
    
    public var body: some Reducer<State, Action> {
        
        Reduce<State, Action> { state, action in
            switch action {
            default:
                return .none
            }
        }
    }
}
