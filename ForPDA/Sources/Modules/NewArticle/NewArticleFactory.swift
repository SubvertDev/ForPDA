//
//  NewArticleFactory.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import RouteComposer

final class NewArticleFactory: Factory {
  
  typealias ViewController = NewArticleVC
  typealias Context = Article
  
    func build(with context: Context) throws -> ViewController {
        let presenter = NewArticlePresenter(article: context)
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        
        return viewController
    }
}
