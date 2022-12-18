//
//  UITextView+Ext.swift
//  ForPDA
//
//  Created by Subvert on 15.12.2022.
//

import UIKit

extension UITextView {
    func textHeightForWidth(_ width: CGFloat) -> CGFloat {
        let storage = NSTextStorage(attributedString: attributedText)
        let width = bounds.width - textContainerInset.horizontal
        let containerSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: containerSize)
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        container.lineFragmentPadding = textContainer.lineFragmentPadding
        container.lineBreakMode = textContainer.lineBreakMode
        _ = manager.glyphRange(for: container)
        let usedHeight = manager.usedRect(for: container).height
        return ceil(usedHeight + textContainerInset.vertical)
    }
}

private extension UIEdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }
}
