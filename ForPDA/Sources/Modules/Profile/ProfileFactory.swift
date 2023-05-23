//
//  ProfileFactory.swift
//  ForPDA
//
//  Created by Subvert on 23.05.2023.
//

import XCoordinator

struct ProfileFactory {
    static func create() -> ProfileVC {
        let viewModel = ProfileVM()
        let viewController = ProfileVC(viewModel: viewModel)
        
        viewModel.view = viewController
        
        return viewController
    }
}
