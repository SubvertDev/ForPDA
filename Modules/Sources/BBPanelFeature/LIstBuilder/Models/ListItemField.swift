//
//  ListItemField.swift
//  ForPDA
//
//  Created by Xialtal on 2.01.26.
//

struct ListItemField: Equatable, Identifiable {
    let id: Int
    var content: String
    
    init(
        id: Int,
        content: String
    ) {
        self.id = id
        self.content = content
    }
}
