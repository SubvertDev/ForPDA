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
    
    public var title: LocalizedStringKey {
        switch self {
        case .byName:
            "By name"
        case .byDate:
            "By date"
        }
    }
}
