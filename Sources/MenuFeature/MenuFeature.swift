//
//  MenuFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct MenuFeature {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        case profileTapped
    }
    
    // MARK: - Dependencies
    
    
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .profileTapped:
                return .none
            }
        }
    }
}

