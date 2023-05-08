//
//  Coordinator.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}
