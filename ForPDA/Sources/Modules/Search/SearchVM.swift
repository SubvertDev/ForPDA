//
//  SearchVM.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import Foundation
import XCoordinator

protocol SearchVMProtocol {
    
}

final class SearchVM: SearchVMProtocol {
    
    private var router: UnownedRouter<SearchRoute>
    weak var view: SearchVCProtocol?
    
    init(router: UnownedRouter<SearchRoute>) {
        self.router = router
    }
    
}
