//
//  NewsFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import ComposableArchitecture

@Reducer
struct NewsFeature {
    
    // MARK: - State
    
    // TODO REMOVE OBSERV?
    @ObservableState
    struct State {
        let news: News
    }
    
    // MARK: - Action
    
    enum Action {
        case optionsButtonTapped
    }
    
    // MARK: - Dependencies
    
    
    
    // MARK: - Body
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .optionsButtonTapped:
                return .none
            }
        }
    }
}
