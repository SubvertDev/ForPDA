//
//  SearchResultFeature.swift
//  ForPDA
//
//  Created by Xialtal on 26.11.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import PersistenceKeys
import SharedUI
import TopicBuilder
import PageNavigationFeature
import ToastClient

@Reducer
public struct SearchResultFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        
        public let search: SearchResult
        
        public var pageNavigation = PageNavigationFeature.State(type: .topic)
        
        public var contentCount = 0
        public var content: [UIContent] = []
        
        var isLoading = false
        
        public init(
            search: SearchResult
        ) {
            self.search = search
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case pageNavigation(PageNavigationFeature.Action)
        
        case view(View)
        public enum View {
            case onFirstAppear
            
            case postTapped(Int, Int)
            case topicTapped(Int, Bool)
            case articleTapped(ArticlePreview)
        }
        
        case `internal`(Internal)
        public enum `Internal` {
            case loadContent(offset: Int)
            case buildContent([SearchContent])
            case searchResponse(Result<SearchResponse, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openArticle(ArticlePreview)
            case openTopic(id: Int, goTo: GoTo)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(.internal(.loadContent(offset: newOffset)))
                
            case .pageNavigation:
                return .none
                
            case .view(.onFirstAppear):
                return .send(.internal(.loadContent(offset: 0)))
                
            case let .view(.postTapped(topicId, postId)):
                return .send(.delegate(.openTopic(id: topicId, goTo: .post(id: postId))))
                
            case let .view(.topicTapped(id, isUnreadTapped)):
                return .send(.delegate(.openTopic(id: id, goTo: isUnreadTapped ? .unread : .first)))
                
            case let .view(.articleTapped(article)):
                var article = article
                article.title = article.title.removeSelectionBBCodes()
                return .send(.delegate(.openArticle(article)))
                
            case let .internal(.loadContent(offset)):
                state.isLoading = true
                return .run { [request = state.search, amount = state.appSettings.topicPerPage] send in
                    let request = SearchRequest(
                        on: request.on,
                        authorId: request.authorId,
                        text: request.text,
                        sort: request.sort,
                        offset: offset,
                        amount: amount
                    )
                    let respone = try await apiClient.search(request)
                    await send(.internal(.searchResponse(.success(respone))))
                } catch: { error, send in
                    await send(.internal(.searchResponse(.failure(error))))
                }
                
            case let .internal(.searchResponse(.success(response))):
                state.content = []
                state.contentCount = response.contentCount
                state.pageNavigation.count = response.contentCount
                return .send(.internal(.buildContent(response.content)))
                
            case let .internal(.buildContent(content)):
                for type in content {
                    switch type {
                    case .post(let post):
                        let topicTypes = TopicNodeBuilder(text: post.post.content.fixBackgroundBBCode(), attachments: post.post.attachments).build()
                        let uiPost = UIPost(post: post.post, content: topicTypes.map { .init(value: $0) } )
                        state.content.append(.post(.init(topicId: post.topicId, topicName: post.topicName.fixBackgroundBBCode(), post: uiPost)))
                    case .topic(let topic):
                        state.content.append(.topic(topic))
                    case .article(let article):
                        state.content.append(.article(article))
                    }
                }
                state.isLoading = false
                return .none
                
            case let .internal(.searchResponse(.failure(error))):
                print(error)
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case .delegate:
                return .none
            }
        }
    }
}
