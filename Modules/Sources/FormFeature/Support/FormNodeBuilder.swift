//
//  FormNodeBuilder.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 20.07.2025.
//

import SharedUI
import SwiftUI
import TopicBuilder

typealias FormNode = UITopicType

// MARK: - Builder

struct FormNodeBuilder {
    
    private let text: String
    
    init(text: String) {
        self.text = text
    }
    
    func build(isDescription: Bool = false) -> [UITopicType] {
        var text = text
        if isDescription {
            text = "[color=gray][size=1]\(text)[/size][/color]"
        }
        return TopicNodeBuilder(text: text, attachments: []).build()
    }
}

// MARK: - View

struct FormNodeView: View {
    
    let node: UITopicType
    
    var body: some View {
        TopicView(
            type: node,
            attachments: [],
            onUrlTap: { _ in
                // We don't process taps on links.
                // If you open them, the form's sheet will close.
                // It works in the official client for topics, because the form opens as a page
                // and links open in new tabs. But it doesn't work properly for posts at all - it breaks the UI.
            }
        )
    }
}
