//
//  NewsFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import ComposableArchitecture
import Models

@Reducer
public struct NewsFeature {
    
    // MARK: - State
    
    // RELEASE: REMOVE OBSERV?
    @ObservableState
    public struct State: Equatable {
        let news: News
        
        public init(news: News) {
            self.news = news
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case optionsButtonTapped
    }
    
    // MARK: - Dependencies
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .optionsButtonTapped:
                return .none
            }
        }
    }
}
