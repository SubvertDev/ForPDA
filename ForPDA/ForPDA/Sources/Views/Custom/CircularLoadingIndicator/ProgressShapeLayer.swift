//
//  ProgressShapeLayer.swift
//  ForPDA
//
//  Created by Subvert on 05.09.2023.
//

import UIKit

final class ProgressShapeLayer: CAShapeLayer {
    
    init(strokeColor: UIColor, lineWidth: CGFloat) {
        super.init()
        
        self.strokeColor = strokeColor.cgColor
        self.lineWidth = lineWidth
        self.fillColor = UIColor.clear.cgColor
        self.lineCap = .round
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
