//
//  PDACharterLabel.swift
//  ForPDA
//
//  Created by Subvert on 06.01.2023.
//

import UIKit

final class PDACharterLabel: PDAPaddingLabel {
    enum PaddingType {
        case left, right
    }
    
    init(text: String, type: PaddingType) {
        super.init(frame: .zero)
        self.text = text
        numberOfLines = 0
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.systemGray.cgColor
        textEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        
        switch type {
        case .left:
            textAlignment = .right
            font = UIFont.systemFont(ofSize: 16, weight: .medium)
        case .right:
            font = UIFont.systemFont(ofSize: 15, weight: .light)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
