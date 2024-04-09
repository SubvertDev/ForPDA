//
//  ArticlePresenter.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import Foundation

protocol ArticlePresenterProtocol {
    var article: Article { get }
}

final class ArticlePresenter: ArticlePresenterProtocol {
    
    // MARK: - Properties
    
    weak var view: ArticleVCProtocol?
    var article: Article
    private var elements: [ArticleElement] = []
    
    // MARK: - Init
    
    init(article: Article) {
        self.article = article
    }
}
