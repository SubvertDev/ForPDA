//
//  CommentsViewDelegate.swift
//  SwiftyComments
//
//  Created by Stéphane Sercu on 12/02/18.
//

import Foundation

public protocol CommentsViewDelegate: AnyObject {
    func commentCellExpanded(atIndex index: Int)
    func commentCellFolded(atIndex index: Int)
}
