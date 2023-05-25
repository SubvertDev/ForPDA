//
//  SettingsFactory.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import XCoordinator

struct SettingsFactory {
    static func create() -> SettingsVC {
        let viewModel = SettingsVM()
        let viewController = SettingsVC(viewModel: viewModel)
        
        viewModel.view = viewController
        
        return viewController
    }
}
