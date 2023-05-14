//
//  SearchVC.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import UIKit

protocol SearchVCProtocol: AnyObject {
    
}

final class SearchVC: PDAViewController<SearchView> {
    
    private let viewModel: SearchVMProtocol
    
    init(viewModel: SearchVMProtocol) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Поиск"
    }
    
}

extension SearchVC: SearchVCProtocol {
    
}
