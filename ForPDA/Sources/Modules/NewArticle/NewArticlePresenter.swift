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
    
    @Injected(\.newsService) private var newsService
    @Injected(\.parsingService) private var parser
    @Injected(\.settingsService) private var settings
    
    weak var view: NewArticleVCProtocol?
    
    var article: Article
    private var path: [String] = []
    
    // MARK: - Init
    
    init(article: Article) {
        self.article = article
        self.path = URL(string: article.url)?.pathComponents ?? []
    }
    
    // MARK: - Public Functions
    
    func loadArticle() async {
        do {
            let response = try await newsService.article(path: path)
            
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
            
            let elements = parser.parseArticle(from: response)
            view?.configureArticle(with: elements)
//            view?.makeComments(from: response)
            
//            await showLikesIfNeeded()
        } catch {
            view?.showError()
        }
    }
    
    func updateComments() async {
        
    }
    
}
