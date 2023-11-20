//
//  ArticlePagesFactory.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.11.2023.
//

import RouteComposer

final class ArticlePagesFactory: Factory {
  
  typealias ViewController = ArticlePagesVC
  typealias Context = Article
  
    func build(with context: Context) throws -> ViewController {
        let presenter = ArticlePagesPresenter(article: context)
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        
        return viewController
    }
}
