//
//  SearchFactory.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import XCoordinator

struct SearchFactory {
    static func create(with router: UnownedRouter<SearchRoute>) -> SearchVC {
        let viewModel = SearchVM(router: router)
        let viewController = SearchVC(viewModel: viewModel)
        
        viewModel.view = viewController
        
        return viewController
    }
}
