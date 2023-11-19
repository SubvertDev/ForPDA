//
//  NewArticlePresenter.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import Foundation

protocol NewArticlePresenterProtocol {
    var article: Article { get }
}

final class NewArticlePresenter: NewArticlePresenterProtocol {
    
    // MARK: - Properties
    
    weak var view: NewArticleVCProtocol?
    var article: Article
    private var elements: [ArticleElement] = []
    
    // MARK: - Init
    
    init(article: Article) {
        self.article = article
    }
}
