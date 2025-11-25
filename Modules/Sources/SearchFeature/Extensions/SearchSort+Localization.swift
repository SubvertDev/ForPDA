//
//  SearchSort+Localization.swift
//  ForPDA
//
//  Created by Xialtal on 25.11.25.
//

import SwiftUI
import Models

extension SearchSort {
    var title: LocalizedStringKey {
        switch self {
        case .dateDescSort:
            return "By Relevance"
        case .dateAscSort:
            return "By Date (newest to oldest)"
        case .relevance:
            return "By Date (oldest to newest)"
        }
    }
}
