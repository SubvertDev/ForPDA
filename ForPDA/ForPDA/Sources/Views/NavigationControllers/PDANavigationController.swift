//
//  PDANavigationController.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.10.2023.
//

import UIKit

final class PDANavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.tintColor = .label
        navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
}
