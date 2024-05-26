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

@Reducer
public struct NewsFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        var news: NewsPreview
        var elements: [NewsElement]
        var isLoading: Bool
        var showShareSheet: Bool
        
        public init(
            news: NewsPreview,
            elements: [NewsElement] = [],
            isLoading: Bool = true,
            showShareSheet: Bool = false
        ) {
            self.news = news
            self.elements = elements
            self.isLoading = isLoading
            self.showShareSheet = showShareSheet
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onTask
        case menuActionTapped(NewsMenuAction)
        case binding(BindingAction<State>)
        
        case _newsResponse(Result<[NewsElement], Error>)
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
                if state.elements.isEmpty {
                    return .run { [news = state.news] send in
                        let result = await Result {
                            try await newsClient.news(url: news.url)
                        }
                        await send(._newsResponse(result))
                    }
                } else {
                    state.isLoading = false
                    return .none // RELEASE: For test purposes only, remove
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
                
            case ._newsResponse(let result):
                switch result {
                case .success(let elements):
                    state.elements = elements
                    state.isLoading = false
                    customDump(elements) // RELEASE: Remove
                case .failure(let error):
                    print("Critical error NewsFeature \(error)") // RELEASE: Handle
                    state.isLoading = false
                }
                return .none
            }
        }
    }
}
