//
//  MenuFactory.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import Foundation

struct MenuFactory {
    static func create(with coordinator: MenuCoordinator) -> MenuVC {
        let viewModel = MenuVM(coordinator: coordinator)
        let viewController = MenuVC(viewModel: viewModel)
        
        // viewModel.view = viewController
        
        return viewController
    }
}
