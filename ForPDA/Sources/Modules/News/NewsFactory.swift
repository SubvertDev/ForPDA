//
//  NewsFactory.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import RouteComposer

final class NewsFactory: Factory {
  
  typealias ViewController = NewsVC
  typealias Context = Any?
  
    func build(with context: Context) throws -> ViewController {
        let presenter = NewsPresenter()
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController

        viewController.title = R.string.localizable.news()
        
        return viewController
    }
}
