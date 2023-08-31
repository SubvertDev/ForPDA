//
//  MenuFactory.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import RouteComposer

final class MenuFactory: Factory {
  
  typealias ViewController = MenuVC
  typealias Context = Any?
  
    func build(with context: Context) throws -> ViewController {
        let presenter = MenuPresenter()
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        // presenter.context = context
        
        viewController.setTabBarItemWith(
            title: R.string.localizable.menu(),
            sfSymbol: .listDash
        )
        
        return viewController
    }
}
