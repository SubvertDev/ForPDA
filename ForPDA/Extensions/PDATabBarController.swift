//
//  PDATabBarController.swift
//  ForPDA
//
//  Created by Subvert on 4.12.2022.
//

import UIKit

final class PDATabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = .systemGroupedBackground
        UITabBar.appearance().standardAppearance = tabBarAppearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        setupVCs()
    }

    private func setupVCs() {
        viewControllers = [
            createNavController(for: NewsVC(), title: "Новости", image: UIImage(systemName: "list.bullet")!),
            createNavController(for: MenuVC(), title: "Профиль", image: UIImage(systemName: "person.fill")!)
        ]
    }

    private func createNavController(for rootVC: UIViewController, title: String,
                                     image: UIImage, prefersLargeTitle: Bool = false) -> UIViewController {
        let navController = UINavigationController(rootViewController: rootVC)
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        navController.navigationBar.prefersLargeTitles = prefersLargeTitle
        rootVC.navigationItem.title = title
        return navController
    }

    private func createController(for rootVC: UIViewController, title: String, image: UIImage) -> UIViewController {
        rootVC.tabBarItem.title = title
        rootVC.tabBarItem.image = image
        return rootVC
    }
}
