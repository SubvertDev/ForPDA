//
//  SettingsFactory.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import RouteComposer

final class SettingsFactory: Factory {
  
  typealias ViewController = SettingsVC
  typealias Context = Any?
  
    func build(with context: Context) throws -> ViewController {
        let presenter = SettingsPresenter()
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        // presenter.context = context
        
        return viewController
    }
}
