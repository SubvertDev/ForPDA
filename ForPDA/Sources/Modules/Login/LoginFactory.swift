//
//  LoginFactory.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

struct LoginFactory {
    static func create() -> LoginVC {
        let viewModel = LoginVM() //(coordinator: coordinator)
        let viewController = LoginVC()
        
        print(viewModel)
        // viewModel.view = viewController
        
        return viewController
    }
}
