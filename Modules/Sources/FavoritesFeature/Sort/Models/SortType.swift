//
//  SortType.swift
//  ForPDA
//
//  Created by Xialtal on 1.01.25.
//

internal enum SortType {
    case byName
    case byDate
    
    public var title: String {
        switch self {
        case .byName:
            "По имени"
        case .byDate:
            "По дате"
        }
    }
}
