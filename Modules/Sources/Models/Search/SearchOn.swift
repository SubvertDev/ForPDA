//
//  SearchOn.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.25.
//

public enum SearchOn: Sendable, Hashable, Equatable {
    case site
    case topic(id: Int, noHighlight: Bool)
    case forum(id: Int?, sIn: ForumSearchIn, asTopics: Bool)
    case profile(ProfileSearchIn)
    
    public enum ProfileSearchIn: Sendable, Equatable {
        case posts
        case topics
    }
}
