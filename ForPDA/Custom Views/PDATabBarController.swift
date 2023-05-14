//
//  PDATabBarController.swift
//  ForPDA
//
//  Created by Subvert on 4.12.2022.
//

import UIKit
import SFSafeSymbols

final class PDATabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        tabBar.tintColor = .label
        
//        let tabBarAppearance = UITabBarAppearance()
//        tabBarAppearance.configureWithDefaultBackground()
//        tabBarAppearance.backgroundColor = .systemGroupedBackground
//        UITabBar.appearance().standardAppearance = tabBarAppearance
//
//        if #available(iOS 15.0, *) {
//            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
//        }
        
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
