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
    
    func loadArticle()
}

final class ArticlePresenter: ArticlePresenterProtocol {
    
    // MARK: - Properties
    
    @Injected(\.networkService) private var networkService
    @Injected(\.parsingService) private var parsingService
    
    weak var view: ArticleVCProtocol?
    
    var article: Article
    
    // MARK: - Init
    
    init(article: Article) {
        self.article = article
    }
    
    // MARK: - Functions
    
    func loadArticle() {
        guard let path = URL(string: article.url)?.pathComponents else {
            view?.showError()
            return
        }
        
        networkService.getArticle(path: path) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                // Deeplink case
                if article.info == nil {
                    let articleInfo = parsingService.parseArticleInfo(from: response)
                    article.info = articleInfo
                    DispatchQueue.main.async {
                        self.view?.reconfigureHeader()
                    }
                }
                
                let elements = parsingService.parseArticle(from: response)
                DispatchQueue.main.async {
                    self.view?.configureArticle(with: elements)
                    self.view?.makeComments(from: response)
                }
                
            case .failure:
                view?.showError()
            }
        }
    }
}
