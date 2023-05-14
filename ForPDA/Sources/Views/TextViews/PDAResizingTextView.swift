//
//  PDAResizingTextView.swift
//  ForPDA
//
//  Created by Subvert on 15.12.2022.
//

import UIKit

protocol PDAResizingTextViewDelegate: AnyObject {
    func willOpenURL(_ url: URL)
}

final class PDAResizingTextView: UITextView {
    
    weak var myDelegate: PDAResizingTextViewDelegate?
    
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
}

extension PDAResizingTextView: UITextViewDelegate {
    
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        myDelegate?.willOpenURL(URL)
        return true
    }
}
