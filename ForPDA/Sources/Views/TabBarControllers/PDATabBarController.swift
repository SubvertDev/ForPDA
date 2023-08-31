//
//  PDATabBarController.swift
//  ForPDA
//
//  Created by Subvert on 4.12.2022.
//

import UIKit

final class PDATabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tabBar.tintColor = .label
        
        delegate = self
        
        // let tabBarAppearance = UITabBarAppearance()
        // tabBarAppearance.configureWithDefaultBackground()
        // tabBarAppearance.backgroundColor = .systemGroupedBackground
        // UITabBar.appearance().standardAppearance = tabBarAppearance

        // if #available(iOS 15.0, *) {
        //     UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        // }
        
        if let viewControllers {
            for controller in viewControllers {
                controller.tabBarItem.title = "\(Int.random(in: 0...1))"
            }
        }
    }
    
    // Tap on tabbar to scroll news to the top
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let viewControllers, !viewControllers.isEmpty else { return true }
        guard viewController == viewControllers[0] && selectedIndex == 0 else { return true }
        guard let navController = viewController as? UINavigationController else { return true }
        guard let topController = navController.viewControllers.last else { return true }

        if topController.isScrolledToTop {
            navController.popViewController(animated: true)
            return true
        } else {
            topController.scrollToTop()
            return false
        }
    }
    
    // Small tap animation for tab bar
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let barItemView = item.value(forKey: "view") as? UIView else { return }

        let timeInterval: TimeInterval = 0.3
        let propertyAnimator = UIViewPropertyAnimator(duration: timeInterval, dampingRatio: 0.5) {
            barItemView.transform = CGAffineTransform.identity.scaledBy(x: 0.9, y: 0.9)
        }
        propertyAnimator.addAnimations({ barItemView.transform = .identity }, delayFactor: CGFloat(timeInterval))
        propertyAnimator.startAnimation()
    }
}
