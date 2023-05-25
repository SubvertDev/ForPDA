//
//  SearchVM.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import Foundation
import XCoordinator

protocol ForumVMProtocol {
    
}

final class ForumVM: ForumVMProtocol {
    
    private var router: UnownedRouter<ForumRoute>
    weak var view: ForumVCProtocol?
    
    init(router: UnownedRouter<ForumRoute>) {
        self.router = router
    }
    
}
