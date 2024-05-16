//
//  SettingsFeature.swift
//
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct SettingsFeature {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        var language = "ru"
        
        public init(
            language: String = "ru"
        ) {
            self.language = language
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case languageTapped
    }
    
    // MARK: - Dependencies
    
    
    
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .languageTapped:
                return .none
            }
        }
    }
}
