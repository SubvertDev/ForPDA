//
//  ArticlePresenter.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import Factory

protocol ArticlePresenterProtocol {
    var article: Article { get }
    
    func loadArticle() async
    func updateComments() async
}

final class ArticlePresenter: ArticlePresenterProtocol {
    
    // MARK: - Properties
    
    @Injected(\.newsService) private var newsService
    @Injected(\.parsingService) private var parsingService
    
    weak var view: ArticleVCProtocol?
    
    var article: Article
    private var path: [String] = []
    
    // MARK: - Init
    
    init(article: Article) {
        self.article = article
        self.path = URL(string: article.url)?.pathComponents ?? []
    }
    
    // MARK: - Public Functions
    
    @MainActor
    func loadArticle() async {
        do {
            let response = try await newsService.article(path: path)
            
            // Deeplink case
            if article.info == nil {
                let articleInfo = parsingService.parseArticleInfo(from: response)
                article.info = articleInfo
                view?.reconfigureHeader()
            }
            
            let elements = parsingService.parseArticle(from: response)
            view?.configureArticle(with: elements)
            view?.makeComments(from: response)
        } catch {
            view?.showError()
        }
    }
    
    @MainActor
    func updateComments() async {
        do {
            let response = try await newsService.article(path: path)
            view?.updateComments(with: response)
        } catch {
            view?.showError()
        }
    }
}
