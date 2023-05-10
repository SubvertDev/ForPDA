//
//  MenuFactory.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import XCoordinator

struct MenuFactory {
    static func create(with router: UnownedRouter<MenuRoute>) -> MenuVC {
        let viewModel = MenuVM(router: router)//(coordinator: coordinator)
        let viewController = MenuVC(viewModel: viewModel)
        
        // viewModel.view = viewController
        
        return viewController
    }
}
