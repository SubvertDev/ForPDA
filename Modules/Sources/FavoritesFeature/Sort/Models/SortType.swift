//
//  SortType.swift
//  ForPDA
//
//  Created by Xialtal on 1.01.25.
//

import SwiftUI

public enum SortType {
    case byName
    case byDate
    
    public var titleLocalized: LocalizedStringKey {
        switch self {
        case .byName:
            return "By name"
        case .byDate:
            return "By date"
        }
    }
    
    public var title: String {
        switch self {
        case .byName:
            return "By name"
        case .byDate:
            return "By date"
        }
    }
}
