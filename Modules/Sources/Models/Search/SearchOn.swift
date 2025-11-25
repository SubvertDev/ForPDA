//
//  SearchOn.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.25.
//

import SwiftUI

public enum SearchOn: Sendable, Hashable, Equatable {
    case site
    case topic(id: Int)
    case forum(id: Int?, sIn: ForumSearchIn, asTopics: Bool)
}
