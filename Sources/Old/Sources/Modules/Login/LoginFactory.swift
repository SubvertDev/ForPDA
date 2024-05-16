//
//  LoginFactory.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

import RouteComposer

final class LoginFactory: Factory {
  
  typealias ViewController = LoginVC
  typealias Context = Any?
  
    func build(with context: Context) throws -> ViewController {
        let presenter = LoginPresenter()
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        // presenter.context = context
        
        return viewController
    }
}
