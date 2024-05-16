//
//  ArticleFactory.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import RouteComposer

final class ArticleFactory: Factory {
    
    typealias ViewController = ArticleVC
    typealias Context = Article
    
    func build(with context: Context) throws -> ViewController {
        let presenter = ArticlePresenter(article: context)
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        
        return viewController
    }
}
