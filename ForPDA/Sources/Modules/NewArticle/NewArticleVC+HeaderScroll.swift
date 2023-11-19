//
//  NewArticle+HeaderScroll.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.11.2023.
//

import UIKit

extension NewArticleVC: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let delta = scrollView.contentOffset.y - oldContentOffset.y
        let topViewCurrentHeightConstant = collectionViewScrollDelegate?.currentHeaderHeight
        if let topViewUnwrappedHeight = topViewCurrentHeightConstant {
            
            /**
             *  Re-size (Shrink) the top view only when the conditions meet:-
             *  1. The current offset of the table view should be greater than the previous offset indicating an upward scroll.
             *  2. The top view's height should be within its minimum height.
             *  3. Optional - Collapse the header view only when the table view's edge is below the above view - This case will occur if you are using Step 2 of the next condition and have a refresh control in the table view.
             */
            
            if delta > 0,
               topViewUnwrappedHeight > collectionViewScrollDelegate?.topViewHeightConstraintRange.lowerBound ?? 0,
               scrollView.contentOffset.y > 0
            {
                dragDirection = .up
                collectionViewScrollDelegate?.innerCollectionViewDidScroll(withDistance: delta)
                scrollView.contentOffset.y -= delta
            }
            
            /**
             *  Re-size (Expand) the top view only when the conditions meet:-
             *  1. The current offset of the table view should be lesser than the previous offset indicating an downward scroll.
             *  2. Optional - The top view's height should be within its maximum height. Skipping this step will give a bouncy effect. Note that you need to write extra code in the outer view controller to bring back the view to the maximum possible height.
             *  3. Expand the header view only when the table view's edge is below the header view, else the table view should first scroll till it's offset is 0 and only then the header should expand.
             */
            
            if delta < 0,
               // topViewUnwrappedHeight < topViewHeightConstraintRange.upperBound,
               scrollView.contentOffset.y < 0
            {
                dragDirection = .down
                collectionViewScrollDelegate?.innerCollectionViewDidScroll(withDistance: delta)
                scrollView.contentOffset.y -= delta
            }
        }
        
        oldContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // You should not bring the view down until the table view has scrolled down to it's top most cell.
        if scrollView.contentOffset.y <= 0 {
            collectionViewScrollDelegate?.innerCollectionViewScrollEnded(withScrollDirection: dragDirection)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // You should not bring the view down until the table view has scrolled down to it's top most cell.
        if decelerate == false && scrollView.contentOffset.y <= 0 {
            collectionViewScrollDelegate?.innerCollectionViewScrollEnded(withScrollDirection: dragDirection)
        }
    }
}
