//
//  ArticlePageControllerDelegate.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.11.2023.
//

import Foundation

protocol ArticlePageControllerDelegate: AnyObject {
    func reconfigureHeader(model: ArticleHeaderViewModel)
    func footerTapped()
}
