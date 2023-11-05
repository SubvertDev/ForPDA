//
//  ArticleTextCellModel.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

struct ArticleTextCellModel: Hashable {
    let text: String
    let isHeader: Bool
    let isQuote: Bool
    let inList: Bool
    let countedListIndex: Int
}
