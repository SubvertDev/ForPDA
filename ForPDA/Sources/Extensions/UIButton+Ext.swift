//
//  UIButton+Ext.swift
//  ForPDA
//
//  Created by Subvert on 22.06.2023.
//

import UIKit

extension UIButton {
    
    var isButtonAnimatingNow: Bool {
        return (self.layer.animationKeys()?.count ?? 0) > 0
    }
    
    func rotate360Degrees(duration: CFTimeInterval = 1, repeatCount: Float = .infinity) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = repeatCount
        layer.add(rotateAnimation, forKey: nil)
    }
    
    func stopButtonRotation(delay: Bool = true) {
        if delay {
            Task {
                try await Task.sleep(nanoseconds: 0_450_000_000)
                layer.removeAllAnimations()
            }
        } else {
            layer.removeAllAnimations()
        }
    }
}
