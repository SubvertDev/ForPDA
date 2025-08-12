//
//  FormNodeBuilder.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 20.07.2025.
//

import BBBuilder
import SharedUI
import SwiftUI

// MARK: - Node

enum FormNode: Hashable {
    case text(AttributedString)
    case center([FormNode])
    case left([FormNode])
    case right([FormNode])
    case justify([FormNode])
}

// MARK: - Builder

struct FormNodeBuilder {
    
    private let text: String
    
    init(text: String) {
        self.text = text
    }
    
    func build(isDescription: Bool = false) -> [FormNode] {
        var text = text
        if isDescription {
            text = "[color=gray][size=1]\(text)[/size][/color]"
        }
        let nodes = BBBuilder.build(text: text)
        return convert(nodes)
    }
    
    private func convert(_ nodes: [BBContainerNode]) -> [FormNode] {
        var elements: [FormNode] = []
        for node in nodes {
            switch node {
            case let .text(text):
                elements.append(.text(AttributedString(text)))
                
            case let .center(nodes), let .left(nodes), let .right(nodes), let .justify(nodes):
                let subElements = convert(nodes)
                elements.append(contentsOf: subElements)
                
            default:
                continue
            }
        }
        return elements
    }
}

// MARK: - View

struct FormNodeView: View {
    
    let node: FormNode
    
    var body: some View {
        switch node {
        case let .text(text):
            RichText(text: text)
            #warning("Обработать тапы на ссылки")
            
        case let .center(nodes), let .justify(nodes):
            VStack(alignment: .center) {
                ForEach(nodes, id: \.self) { node in
                    FormNodeView(node: node)
                }
            }
            
        case let .left(nodes):
            VStack(alignment: .leading) {
                ForEach(nodes, id: \.self) { node in
                    FormNodeView(node: node)
                }
            }
            
        case let .right(nodes):
            VStack(alignment: .trailing) {
                ForEach(nodes, id: \.self) { node in
                    FormNodeView(node: node)
                }
            }
        }
    }
}
