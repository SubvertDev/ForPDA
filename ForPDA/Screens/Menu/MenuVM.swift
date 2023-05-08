//
//  MenuVM.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import Foundation

protocol MenuVMProtocol {
    func showLoginScreen()
}

final class MenuVM: MenuVMProtocol {
    
    weak var coordinator: MenuCoordinator?
    
    // weak var view: MenuVCProtocol
    
    init(coordinator: MenuCoordinator) {
        self.coordinator = coordinator
    }
    
    func showLoginScreen() {
        coordinator?.showLoginScreen()
    }
    
}
