//
//  ForumVC.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import UIKit

protocol ForumVCProtocol: AnyObject {
    
}

final class ForumVC: PDAViewController<ForumView> {
    
    private let viewModel: ForumVMProtocol
    
    init(viewModel: ForumVMProtocol) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.localizable.forum()
    }
    
}

extension ForumVC: ForumVCProtocol {
    
}
