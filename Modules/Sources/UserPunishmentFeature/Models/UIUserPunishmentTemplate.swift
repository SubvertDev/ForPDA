//
//  UIUserPunishmentCategory.swift
//  ForPDA
//
//  Created by Xialtal on 6.09.26.
//

import Models

struct UIUserPunishmentCategory: Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let supportsRestrictions: Bool
    var template: UserPunishmentTemplate
    
    init(
        id: String,
        title: String,
        supportsRestrictions: Bool,
        template: UserPunishmentTemplate
    ) {
        self.id = id
        self.title = title
        self.supportsRestrictions = supportsRestrictions
        self.template = template
    }
}

extension UIUserPunishmentCategory {
    static let `default` = UIUserPunishmentCategory(
        id: "default",
        title: "Loading...",
        supportsRestrictions: false,
        template: .default
    )
}
