//
//  MenuFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture

@Reducer
struct MenuFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State {
        
    }
    
    // MARK: - Action
    
    enum Action {
        case profileTapped
    }
    
    // MARK: - Dependencies
    
    
    
    // MARK: - Body
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .profileTapped:
                return .none
            }
        }
    }
}

