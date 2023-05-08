//
//  NewsFactory.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import Foundation

struct NewsFactory {
    static func create(with coordinator: NewsCoordinator) -> NewsVC {
        let viewModel = NewsVM(coordinator: coordinator)
        let viewController = NewsVC(viewModel: viewModel)
        
        viewModel.view = viewController
        
        return viewController
    }
}
