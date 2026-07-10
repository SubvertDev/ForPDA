//
//  TicketsSettings.swift
//  ForPDA
//
//  Created by Xialtal on 9.05.26.
//

public struct TicketsSettings: Sendable, Codable, Hashable {
    public var isSortByForums: Bool
    public var isShowOnlyMine: Bool
    
    public init(
        isSortByForums: Bool,
        isShowOnlyMine: Bool
    ) {
        self.isSortByForums = isSortByForums
        self.isShowOnlyMine = isShowOnlyMine
    }
    
    public func asDictionary() -> [String: Any] {
        return [
            "isSortByForums": isSortByForums,
            "isShowOnlyMine": isShowOnlyMine
        ]
    }
}

extension TicketsSettings {
    static let `default` = TicketsSettings(
        isSortByForums: false,
        isShowOnlyMine: false
    )
}
