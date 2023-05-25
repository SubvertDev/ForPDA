//
//  PDATableView.swift
//  ForPDA
//
//  Created by Subvert on 06.01.2023.
//

import UIKit

final class PDATableView: UITableView {
    
    override func layoutSubviews() {
        guard window != nil else { return }
        super.layoutSubviews()
    }
}
