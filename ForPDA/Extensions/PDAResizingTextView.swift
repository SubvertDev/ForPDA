//
//  PDAResizingTextView.swift
//  ForPDA
//
//  Created by Subvert on 15.12.2022.
//

import UIKit

final class PDAResizingTextView: UITextView {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        isScrollEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point) else { return false }
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        preferredMaxLayoutWidth = bounds.width
//    }
    
//    private var preferredMaxLayoutWidth: CGFloat? {
//        didSet {
//            guard preferredMaxLayoutWidth != oldValue else { return }
//            invalidateIntrinsicContentSize()
//        }
//    }
    
//    override var attributedText: NSAttributedString! {
//        didSet {
//            invalidateIntrinsicContentSize()
//        }
//    }
    
//    override var intrinsicContentSize: CGSize {
//        guard let width = preferredMaxLayoutWidth else {
//            return super.intrinsicContentSize
//        }
//        return CGSize(width: width, height: textHeightForWidth(width))
//    }
}
