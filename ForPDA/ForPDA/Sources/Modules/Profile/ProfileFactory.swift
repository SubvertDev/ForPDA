//
//  ProfileFactory.swift
//  ForPDA
//
//  Created by Subvert on 23.05.2023.
//

import RouteComposer

final class ProfileFactory: Factory {
  
  typealias ViewController = ProfileVC
  typealias Context = Any?
  
    func build(with context: Context) throws -> ViewController {
        let presenter = ProfilePresenter()
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        // presenter.context = context
        
        return viewController
    }
}
