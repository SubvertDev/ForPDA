//
//  ArticleVM.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import Factory
import XCoordinator

protocol ArticleVMProtocol {
    var article: Article { get }
    
    func loadArticle()
}

final class ArticleVM: ArticleVMProtocol {
    
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
                let elements = parsingService.parseArticle(from: response)
                view?.configureArticle(with: elements)
                view?.configureComments(from: response)
                
            case .failure:
                view?.showError()
            }
        }
    }
}
