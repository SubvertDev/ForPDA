//
//  AppSettings.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import Foundation

public enum ArticlesListRowType: String, Sendable, Equatable, Codable {
    case normal
    case short
}

public struct AppSettings: Sendable, Equatable, Codable {
    
    public var articlesListRowType: ArticlesListRowType
    
    public init(
        articlesListRowType: ArticlesListRowType
    ) {
        self.articlesListRowType = articlesListRowType
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.articlesListRowType = try container.decodeIfPresent(ArticlesListRowType.self, forKey: .articlesListRowType) ?? AppSettings.default.articlesListRowType
    }
}

public extension AppSettings {
    static let `default` = AppSettings(
        articlesListRowType: .normal
    )
}
