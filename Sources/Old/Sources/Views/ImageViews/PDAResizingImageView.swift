//
//  PDAResizingImageView.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import UIKit

final class PDAResizingImageView: UIImageView {
    
    private var layoutedWidth: CGFloat = 0

    override var intrinsicContentSize: CGSize {
        layoutedWidth = bounds.width
        if let image = self.image {
            let viewWidth = bounds.width
            let ratio = viewWidth / image.size.width
            return CGSize(width: viewWidth, height: image.size.height * ratio)
        }
        return super.intrinsicContentSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if layoutedWidth != bounds.width {
            invalidateIntrinsicContentSize()
        }
    }

}
