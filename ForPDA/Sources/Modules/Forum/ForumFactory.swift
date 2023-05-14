//
//  ForumFactory.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import XCoordinator

struct ForumFactory {
    static func create(with router: UnownedRouter<ForumRoute>) -> ForumVC {
        let viewModel = ForumVM(router: router)
        let viewController = ForumVC(viewModel: viewModel)
        
        viewModel.view = viewController
        
        return viewController
    }
}
