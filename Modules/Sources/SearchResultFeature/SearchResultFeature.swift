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
import CacheClient
import PasteboardClient

@Reducer
public struct SearchResultFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    private enum Localization {
        static let linkCopied = LocalizedStringResource("Link copied", bundle: .module)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        var userSessionInfo: User?
        
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
            
            case contextMenu(SearchResultContextMenuAction)
        }
        
        case `internal`(Internal)
        public enum `Internal` {
            case loadContent(offset: Int)
            case buildContent([SearchContent])
            case searchResponse(Result<SearchResponse, any Error>)
            
            case initUserSessionInfo(User)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openArticle(ArticlePreview)
            case openTopic(id: Int, goTo: GoTo)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    @Dependency(\.toastClient) private var toastClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(\.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(.internal(.loadContent(offset: newOffset)))
                
            case .pageNavigation:
                return .none
                
            case .view(.onFirstAppear):
                return .run { [session = state.userSession] send in
                    if let session, let user = cacheClient.getUser(session.userId) {
                        await send(.internal(.initUserSessionInfo(user)))
                    }
                    await send(.internal(.loadContent(offset: 0)))
                }
                
            case let .view(.postTapped(topicId, postId)):
                return .send(.delegate(.openTopic(id: topicId, goTo: .post(id: postId))))
                
            case let .view(.topicTapped(id, isUnreadTapped)):
                return .send(.delegate(.openTopic(id: id, goTo: isUnreadTapped ? .unread : .first)))
                
            case let .view(.articleTapped(article)):
                var article = article
                article.title = article.title.removeSelectionBBCodes()
                return .send(.delegate(.openArticle(article)))
                
            case let .view(.contextMenu(action)):
                switch action {
                case .copyLink:
                    let params = buildSearchQueryParams(search: state.search, forInternalLink: false)
                    let path = state.search.on != .site ? "forum/index.php?act=search" : ""
                    pasteboardClient.copy("https://4pda.to/" + path + params)
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.linkCopied, haptic: .success))
                    }
                }
                
            case let .internal(.loadContent(offset)):
                state.isLoading = true
                return .run { [request = state.search, amount = state.appSettings.topicPerPage] send in
                    let request = SearchRequest(
                        on: request.on,
                        author: request.author,
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
                
            case let .internal(.initUserSessionInfo(user)):
                state.userSessionInfo = user
                return .none
                
            case .delegate:
                return .none
            }
        }
        
        Analytics()
    }
    
    // MARK: - Helpers
    
    private func buildSearchQueryParams(search: SearchResult, forInternalLink: Bool) -> String {
        let rawText = if let data = search.text.data(using: .windowsCP1251) {
            data.map { String(format: "%%%02X", $0) }.joined()
        } else {
            search.text.replacingOccurrences(of: " ", with: "+")
        }
        let text = search.on != .site ? "&query=\(rawText)" : rawText
        
        let searchOn: String
        switch search.on {
        case .site:
            searchOn = "?s="
            
        case .topic(let ids, let noHighlight):
            let ids = !ids.isEmpty ? "&topics=\(ids.map { String($0) }.joined(separator: ","))" : ""
            let sIn = "&source=\(ForumSearchIn.all.rawValue)"
            let noHighlight = noHighlight ? "&nohl=1" : ""
            
            searchOn = sIn + ids + noHighlight
            
        case .forum(let ids, let sIn, let asTopics):
            let ids = !ids.isEmpty ? "&forums=\(ids.map { String($0) }.joined(separator: ","))" : ""
            let sIn = "&source=\(sIn.rawValue)"
            let asTopics = asTopics ? "&result=topics" : ""
            
            searchOn = sIn + asTopics + ids + "&subforums=1"
            
        case .profile(let type):
            searchOn = switch type {
            case .posts:  "&source=\(ForumSearchIn.posts.rawValue)"
            case .topics: "&source=\(ForumSearchIn.titles.rawValue)"
            }
        }
        
        let sort = if forInternalLink || search.on != .site {
            search.sort != .relevance ? "&sort=\(search.sort.rawValue)" : ""
        } else { "" }
        
        let username = if (forInternalLink || search.on != .site), let author = search.author {
            switch author {
            case .id(let id):     
                id != 0 ? "&username-id=\(id)" : ""
            case .name(let name):
                !name.isEmpty ? "&username=\(name)" : ""
            }
        } else { "" }
        
        return searchOn + text + sort + username
    }
}
