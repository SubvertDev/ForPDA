//
//  NewsFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import Models
import NewsClient
import PasteboardClient

@Reducer
public struct NewsFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        var news: News
//        var news: NewsPreview
//        var elements: [NewsElement]
        var isLoading: Bool
        var showShareSheet: Bool
        
        public init(
            news: News,
//            news: NewsPreview,
//            elements: [NewsElement] = [],
            isLoading: Bool = true,
            showShareSheet: Bool = false
        ) {
            self.news = news
//            self.news = news
//            self.elements = elements
            self.isLoading = isLoading
            self.showShareSheet = showShareSheet
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onTask
        case menuActionTapped(NewsMenuAction)
        case linkInTextTapped(URL)
        case delegate(Delegate)
        case binding(BindingAction<State>)
        
        case _newsResponse(Result<News, Error>)
        
        @CasePathable
        public enum Delegate {
            case handleDeeplink(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.newsClient) var newsClient
    @Dependency(\.pasteboardClient) var pasteboardClient
    @Dependency(\.openURL) var openURL
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onTask:
                if state.news.elements.isEmpty {
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
                
            case let .linkInTextTapped(url):
                return .run { send in
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                        if let host = components.host, host.contains("4pda") {
                            await send(.delegate(.handleDeeplink(url)))
                            return
                        }
                    }
                    await openURL(url)
                }
                
            case .binding, .delegate:
                return .none
                
            case ._newsResponse(let result):
                switch result {
                case .success(let news):
                    // In-app deeplink
                    if state.news.preview.description.isEmpty { // RELEASE: Make test for empty description
                        state.news.preview = news.preview
                    }
                    state.news.elements = news.elements
                    state.isLoading = false
                    customDump(news.elements) // RELEASE: Remove
                    
                case .failure(let error):
                    print("Critical error NewsFeature \(error)") // RELEASE: Handle
                    state.isLoading = false
                }
                return .none
            }
        }
    }
}
