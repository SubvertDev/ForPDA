//
//  PDATabBarControllerFactory.swift
//  ForPDA
//
//  Created by Subvert on 19.08.2023.
//

import UIKit
import RouteComposer

struct PDATabBarControllerFactory<TBC: UITabBarController, C>: SimpleContainerFactory {
    
    typealias ViewController = TBC
    
    typealias Context = C
    
    /// `UITabBarControllerDelegate` reference
    private(set) public weak var delegate: UITabBarControllerDelegate?
    
    /// Block to configure `UITabBarController`
    public let configuration: ((_: UITabBarController) -> Void)?
    
    /// Constructor
    public init(delegate: UITabBarControllerDelegate? = nil,
                configuration: ((_: UITabBarController) -> Void)? = nil) {
        self.delegate = delegate
        self.configuration = configuration
    }
    
    func build(with context: C, integrating viewControllers: [UIViewController]) throws -> TBC {
        guard !viewControllers.isEmpty else {
            throw RoutingError.compositionFailed(.init("Unable to build UITabBarController due " +
                                                       "to 0 amount of the children view controllers"))
        }
        let tabBarController = TBC()
        if let delegate = delegate {
            tabBarController.delegate = delegate
        }
        if let configuration = configuration {
            configuration(tabBarController)
        }
        tabBarController.viewControllers = viewControllers
        return tabBarController
    }
}
