import Foundation
import Testing
import Models
import ComposableArchitecture

@testable import ArticlesListFeature

@MainActor
@Suite("Articles List Tests")
struct ArticlesListFeatureTest {
    
    init() { uncheckedUseMainSerialExecutor = true }
    
    @Test("Success on appear")
    func onAppearSuccess() async throws {
        let articles: [ArticlePreview] = Array(repeating: .mock, count: 15)
        
        let store = TestStore(initialState: ArticlesListFeature.State()) {
            ArticlesListFeature()
        } withDependencies: {
            $0.apiClient.getArticlesList = { @Sendable _, _ in
                return articles
            }
        }
        
        await store.send(.onAppear)
        
        await store.receive(\._articlesResponse.success) {
            $0.articles = articles
            $0.offset = articles.count
            $0.isLoading = false
        }
    }
    
    @Test("Failure on appear")
    func onAppearFailure() async throws {
        let store = TestStore(initialState: ArticlesListFeature.State()) {
            ArticlesListFeature()
        } withDependencies: {
            $0.apiClient.getArticlesList = { @Sendable _, _ in
                // TODO: Add my own errors
                throw NSError(domain: "Network", code: 1)
            }
        }
        
        await store.send(.onAppear)
        
        await store.receive(\._articlesResponse.failure) {
            $0.isLoading = false
            $0.destination = .alert(.failedToConnect)
        }
    }
    
    @Test("No loading when there are articles")
    func onAppearNonEmpty() async throws {
        let articles: [ArticlePreview] = Array(repeating: .mock, count: 15)
        
        let store = TestStore(initialState: ArticlesListFeature.State(articles: articles)) {
            ArticlesListFeature()
        } withDependencies: {
            $0.apiClient.getArticlesList = { @Sendable _, _ in
                return articles
            }
        }
        
        await store.send(.onAppear)
    }
    
    @Test("Pull to refresh")
    func refresh() async throws {
        let perPage = 15
        let articles: [ArticlePreview] = Array(repeating: .mock, count: perPage)
        
        let store = TestStore(initialState: ArticlesListFeature.State(articles: articles)) {
            ArticlesListFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.apiClient.getArticlesList = { @Sendable _, _ in
                return articles
            }
        }
        
        await store.send(.onRefresh)
        
        await store.receive(\._articlesResponse.success) {
            $0.articles = articles
            $0.offset = perPage
            $0.isLoading = false
        }
    }
    
    @Test("Pagination loading", arguments: [15, 20, 30])
    func loadMoreArticles(perPage: Int) async throws {
        let initialArticles: [ArticlePreview] = Array(repeating: .mock, count: perPage)
        let loadedArticles = initialArticles

        let store = TestStore(
            initialState: ArticlesListFeature.State(
                articles: initialArticles,
                isLoading: false,
                loadAmount: perPage,
                offset: perPage
            )
        ) {
            ArticlesListFeature()
        } withDependencies: {
            $0.apiClient.getArticlesList = { @Sendable _, _ in
                return loadedArticles
            }
        }
        
        await store.send(.loadMoreArticles) {
            $0.isLoading = true
        }
        
        await store.receive(\._articlesResponse.success) {
            $0.articles = initialArticles + loadedArticles
            $0.offset = perPage + perPage
            $0.isLoading = false
        }
    }
    
    @Test("All cell menu options")
    func cellMenuOptions() async throws {
        let store = TestStore(initialState: ArticlesListFeature.State()) {
            ArticlesListFeature()
        }
        
        for options in ContextMenuOptions.allCases {
            switch options {
            case .shareLink:
                await store.send(.cellMenuOpened(.mock, .shareLink)) {
                    $0.destination = .share(ArticlePreview.mock.url)
                }
                
                await store.send(.linkShared(true, URL(string: "/")!)) {
                    $0.destination = nil
                }
                
            case .copyLink:
                await store.send(.cellMenuOpened(.mock, .copyLink))

            case .openInBrowser:
                await store.send(.cellMenuOpened(.mock, .openInBrowser))

            case .report:
                // TODO: Report
                break
                
            case .addToBookmarks:
                await store.send(.cellMenuOpened(.mock, .addToBookmarks)) {
                    $0.destination = .alert(.notImplemented)
                }
            }
        }
    }
    
    @Test("List grid view options")
    func listGridViewOptions() async throws {
        let store = TestStore(
            initialState: ArticlesListFeature.State()
        ) {
            ArticlesListFeature()
        }
        
        await store.send(.listGridTypeButtonTapped) {
            $0.listRowType = .normal
        }
        
        store.assert { $0.appSettings.articlesListRowType = .normal }
        
        await store.send(.listGridTypeButtonTapped) {
            $0.listRowType = .short
        }
        
        store.assert { $0.appSettings.articlesListRowType = .short }
    }
}
