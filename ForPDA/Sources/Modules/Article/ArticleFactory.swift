//
//  ArticleFactory.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

import RouteComposer

final class ArticleFactory: Factory {
  
  typealias ViewController = ArticleVC
  typealias Context = Article
  
    func build(with context: Context) throws -> ViewController {
        let presenter = ArticlePresenter(article: context)
        let viewController = ViewController(presenter: presenter)
//        presenter.view = viewController
        
        return viewController
    }
}
