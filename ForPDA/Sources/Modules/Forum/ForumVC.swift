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
    
    private let presenter: ForumPresenterProtocol
    
    init(presenter: ForumPresenterProtocol) {
        self.presenter = presenter
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}

extension ForumVC: ForumVCProtocol {
    
}
