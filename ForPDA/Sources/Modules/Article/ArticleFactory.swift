//
//  ArticleFactory.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

import XCoordinator

struct ArticleFactory {
    static func create(with article: Article) -> ArticleVC {
        let viewModel = ArticleVM(article: article)
        let viewController = ArticleVC(viewModel: viewModel)
        
        viewModel.view = viewController
        
        return viewController
    }
}
