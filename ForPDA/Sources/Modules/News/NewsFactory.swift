//
//  NewsFactory.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import XCoordinator

struct NewsFactory {
    static func create(with router: UnownedRouter<NewsRoute>) -> NewsVC {
        let viewModel = NewsVM(router: router)
        let viewController = NewsVC(viewModel: viewModel)
        
        viewModel.view = viewController
        
        return viewController
    }
}
