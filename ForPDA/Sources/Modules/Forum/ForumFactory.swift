//
//  ForumFactory.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import RouteComposer

final class ForumFactory: Factory {
  
  typealias ViewController = ForumVC
  typealias Context = Any?
  
    func build(with context: Context) throws -> ViewController {
        let presenter = ForumPresenter()
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        
        viewController.title = R.string.localizable.forum()
        
        viewController.setTabBarItemWith(
            title: R.string.localizable.forum(),
            sfSymbol: .bubbleLeftAndBubbleRightFill
        )
        
        return viewController
    }
}
