//
//  StrokeColorAnimation.swift
//  ForPDA
//
//  Created by Subvert on 05.09.2023.
//

import UIKit

final class StrokeColorAnimation: CAKeyframeAnimation {
    
    override init() {
        super.init()
    }
    
    init(colors: [CGColor], duration: Double) {
        super.init()
        self.keyPath = "strokeColor"
        self.values = colors
        self.duration = duration
        self.repeatCount = .greatestFiniteMagnitude
        self.timingFunction = .init(name: .easeInEaseOut)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
