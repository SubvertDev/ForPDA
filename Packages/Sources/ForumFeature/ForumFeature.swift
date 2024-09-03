//
//  File.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.09.2024.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct ForumFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        
    }
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            }
        }
    }
}
