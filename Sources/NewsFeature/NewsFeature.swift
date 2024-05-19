//
//  NewsFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import ComposableArchitecture
import Models
import NewsClient
import PasteboardClient

public enum MenuAction: String {
    case copyLink = "Скопировано"
    case shareLink
    case report = "Скоро починим :)"
}

@Reducer
public struct NewsFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        let news: NewsPreview
//        let elements: [any Models.NewsElement] = [] // RELEASE: Remove "Models."
        var isLoading: Bool
        var showShareSheet: Bool
        
        public init(
            news: NewsPreview,
//            elements: [any Models.NewsElement] = [], // RELEASE: Remove "Models."
            isLoading: Bool = true,
            showShareSheet: Bool = false
        ) {
            self.news = news
//            self.elements = elements
            self.isLoading = isLoading
            self.showShareSheet = showShareSheet
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onTask
        case menuActionTapped(MenuAction)
        case binding(BindingAction<State>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.newsClient) var newsClient
    @Dependency(\.pasteboardClient) var pasteboardClient
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onTask:
                return .run { [news = state.news] send in
//                    let elements = try! await newsClient.news(url: news.url)
                    print(news)
                }
                
            case let .menuActionTapped(action):
                switch action {
                case .copyLink:
                    pasteboardClient.copy(url: state.news.url)
                    
                case .shareLink:
                    state.showShareSheet = true
                    
                case .report:
                    break
                }
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
