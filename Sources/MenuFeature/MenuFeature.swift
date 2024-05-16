//
//  MenuFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import SharedUI

@Reducer
public struct MenuFeature {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        var loggedIn = false
        
        public init(
            loggedIn: Bool = false
        ) {
            self.loggedIn = loggedIn
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case profileTapped
        case settingsTapped
    }
    
    // MARK: - Dependencies
    
    
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .profileTapped:
                return .none
                
            case .settingsTapped:
                return .none
            }
        }
    }
}
