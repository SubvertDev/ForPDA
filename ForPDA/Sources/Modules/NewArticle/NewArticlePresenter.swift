//
//  NewArticlePresenter.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import Foundation
import Factory

protocol NewArticlePresenterProtocol {
    var article: Article { get }
    
    func loadArticle() async
    func updateComments() async
}

final class NewArticlePresenter: NewArticlePresenterProtocol {
    
    // MARK: - Properties
    
    @Injected(\.newsService) private var news
    @Injected(\.parsingService) private var parser
    @Injected(\.settingsService) private var settings
    
    weak var view: NewArticleVCProtocol?
    
    var article: Article
    private var path: [String] = []
    private var elements: [ArticleElement] = []
    
    // MARK: - Init
    
    init(article: Article) {
        self.article = article
        self.path = URL(string: article.url)?.pathComponents ?? []
    }
    
    // MARK: - Public Functions
    
    @MainActor
    func loadArticle() async {
        do {
            let response = try await news.article(path: path)
            
            // When opening through deeplink we don't have ArticleInfo
            // so we need to parse it first to show the header
            if article.info == nil {
                let articleInfo = parser.parseArticleInfo(from: response)
                article.info = articleInfo
                let model = ArticleHeaderViewModel(
                    imageUrl: articleInfo.imageUrl,
                    title: articleInfo.title
                )
                view?.reconfigureHeader(model: model)
            }
            
            async let elements = parser.parseArticle(from: response)
            async let comments = parser.parseComments(from: response)
            
            // Saving elements to update comments later via diffable
            self.elements = await elements
            
            // If FLS enabled & we need to show likes, download them at start or
            // it will lag a second later when we trying to show them again in updateComments()
//            var comments: [Comment]
//            var commentsResponse = ""
//            if settings.getFastLoadingSystem() && settings.getShowLikesInComments() {
//                commentsResponse = try await news.comments(path: path)
//            }
//            let responseToParse = commentsResponse.isEmpty ? response : commentsResponse
//            comments = parser.parseComments(from: responseToParse)
            
            view?.configureArticle(elements: await elements, comments: await comments, commentsRefresh: false)
            
            await showLikesIfNeeded()
        } catch {
            view?.showError()
        }
    }
    
    @MainActor
    func updateComments() async {
        do {
            let response = try await news.comments(path: path)
            let comments = parser.parseComments(from: response)
            view?.configureArticle(elements: elements, comments: comments, commentsRefresh: true)
        } catch {
            view?.showError()
        }
    }
    
    // MARK: - Private Functions
    
    private func showLikesIfNeeded() async {
        let isFLSEnabled = settings.getFastLoadingSystem()
        let showLikes = settings.getShowLikesInComments()
        
        if isFLSEnabled && showLikes {
            await updateComments()
        }
    }
    
}
