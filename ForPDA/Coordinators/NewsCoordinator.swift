//
//  NewsCoordinator.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit

protocol NewsCoordinatorProtocol {
    func showArticle(_ article: Article)
}

final class NewsCoordinator: Coordinator, NewsCoordinatorProtocol {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let newsVC = NewsFactory.create(with: self)
        navigationController.tabBarItem.title = "Новости"
        navigationController.tabBarItem.image = UIImage(systemName: "list.bullet")
        navigationController.pushViewController(newsVC, animated: false)
    }
    
    func showArticle(_ article: Article) {
        // TODO: Sdelat norm
        let articleVC = ArticleVC(article: article)
        navigationController.setNavigationBarHidden(false, animated: true)
        navigationController.pushViewController(articleVC, animated: true)
    }
}
