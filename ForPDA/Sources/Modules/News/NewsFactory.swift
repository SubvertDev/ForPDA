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
        // presenter.context = context

        viewController.title = R.string.localizable.news()
        
        viewController.setTabBarItemWith(
            title: R.string.localizable.news(),
            sfSymbol: .newspaperFill
        )
        
        return viewController
    }
}
