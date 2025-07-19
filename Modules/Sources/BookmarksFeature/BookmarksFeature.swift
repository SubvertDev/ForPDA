//
//  BookmarksFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import Foundation
import ComposableArchitecture
import TCAExtensions
import APIClient
import PasteboardClient
import Models
import PersistenceKeys

@Reducer
public struct BookmarksFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        case onAppear
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
