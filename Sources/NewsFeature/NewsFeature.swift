//
//  NewsFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import ComposableArchitecture
import Models
import NewsClient

@Reducer
public struct NewsFeature {
    
    // MARK: - State
    
    // RELEASE: REMOVE OBSERV?
    @ObservableState
    public struct State: Equatable {
        let news: NewsPreview
//        let elements: [any Models.NewsElement] = [] // RELEASE: Remove "Models."
        var isLoading = true
        
        public init(
            news: NewsPreview,
//            elements: [any Models.NewsElement] = [], // RELEASE: Remove "Models."
            isLoading: Bool = true
        ) {
            self.news = news
//            self.elements = elements
            self.isLoading = isLoading
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case optionsButtonTapped
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.newsClient) var newsClient
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                return .run { [news = state.news] send in
//                    let elements = try! await newsClient.news(url: news.url)
                    print(news)
                }
                
            case .optionsButtonTapped:
                return .none
            }
        }
    }
}
