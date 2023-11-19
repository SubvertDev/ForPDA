//
//  ArticlePagesPresenter.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 18.11.2023.
//

import Foundation
import Factory

protocol ArticlePagesPresenterProtocol {
    var article: Article { get }
    
    func loadArticle() async
}

final class ArticlePagesPresenter: ArticlePagesPresenterProtocol {
    
    // MARK: - Properties
    
    @Injected(\.newsService) private var news
    @Injected(\.parsingService) private var parser
    @Injected(\.settingsService) private var settings
    
    weak var view: (ArticlePagesVCProtocol & Alertable)?
    
    var article: Article
    
    // MARK: - Init
    
    init(article: Article) {
        self.article = article
    }
    
    // MARK: - Public Functions
    
    func loadArticle() async {
        do {
            let response = try await news.article(path: article.path)
            
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
            
            view?.configureArticle(elements: await elements, comments: await comments)
        } catch {
            view?.showAlert(title: R.string.localizable.error(), message: error.localizedDescription)
        }
    }
}
