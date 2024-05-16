//
//  ArticleImageWithTextCellModel.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import Foundation

struct ArticleImageWithTextCellModel: Hashable {
    let imageUrl: URL
    let description: String
    let width: Int
    let height: Int
}
