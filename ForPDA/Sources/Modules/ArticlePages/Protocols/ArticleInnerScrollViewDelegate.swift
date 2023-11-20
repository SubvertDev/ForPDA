//
//  ArticleInnerScrollViewDelegate.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.11.2023.
//

import Foundation

protocol ArticleInnerScrollViewDelegate: AnyObject {
    var currentHeaderHeight: CGFloat { get }
    var topViewHeightConstraintRange: Range<CGFloat> { get }
    
    func innerCollectionViewDidScroll(withDistance scrollDistance: CGFloat)
    func innerCollectionViewScrollEnded(withScrollDirection scrollDirection: DragDirection)
}
