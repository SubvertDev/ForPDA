//
//  SentryCustomError.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.11.2023.
//

import Foundation

enum SentryCustomError: Error {
    case badArticle(url: String)
}
