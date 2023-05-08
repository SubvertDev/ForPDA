//
//  MenuCoordinator.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit

protocol MenuCoordinatorProtocol {
    func showLoginScreen()
}

final class MenuCoordinator: Coordinator, MenuCoordinatorProtocol {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let menuVC = MenuFactory.create(with: self)
        navigationController.tabBarItem.title = "Меню"
        navigationController.tabBarItem.image = UIImage(systemName: "person.fill")
        navigationController.pushViewController(menuVC, animated: false)
    }
    
    func showLoginScreen() {
        let loginVC = LoginVC()
        navigationController.pushViewController(loginVC, animated: true)
    }
    
}
