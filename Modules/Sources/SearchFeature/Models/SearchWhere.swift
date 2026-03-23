//
//  SearchWhere.swift
//  ForPDA
//
//  Created by Xialtal on 25.11.25.
//

import SwiftUI
import Models

public enum SearchWhere: Sendable {
    case site
    case topic
    case forum
    case forumById
}

extension SearchWhere {
    var title: LocalizedStringKey {
        return switch self {
        case .site:  "On Site"
        case .topic: "On Topic"
        case .forum: "On Forum"
        case .forumById:
            fatalError("Unexpected usage")
        }
    }
}
