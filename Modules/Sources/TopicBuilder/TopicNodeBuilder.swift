//
//  TopicNodeBuilder.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.03.2025.
//

import Foundation
import Models
import BBBuilder
import SharedUI

public struct TopicNodeBuilder {
    
    private let text: String
    private let attachments: [Attachment]
    
    public init(text: String, attachments: [Attachment]) {
        self.text = text
        self.attachments = attachments
    }
    
    public func build() -> [UITopicType] {
        let nodes = BBBuilder.build(text: text, attachments: attachments)
        return convert(nodes)
    }
    
    private func convert(_ nodes: [BBContainerNode]) -> [UITopicType] {
        var elements: [UITopicType] = []
        for node in nodes {
            switch node {
            case .text(let string):
                elements.append(.text(AttributedString(string)))
                
            case .center(let array):
                let subElements = convert(array)
                elements.append(.center(subElements))
                
            case .left(let array):
                let subElements = convert(array)
                elements.append(.left(subElements))
                
            case .right(let array):
                let subElements = convert(array)
                elements.append(.right(subElements))
                
            case .justify(let array):
                let subElements = convert(array)
                elements.append(.center(subElements)) // TODO: Add justify
                
            case .spoiler(let attributed, let array):
                let subElements = convert(array)
                elements.append(.spoiler(subElements, attributed.map { AttributedString($0) }))
                
            case .quote(let attributed, let array):
                let subElements = convert(array)
                elements.append(.quote(subElements, parseQuoteAttributes(attributed?.string)))
                
            case .list(_, let array):
                let subElements = convert(array)
                elements.append(.list(subElements, .bullet))
                
            case .code(let attribute, let array):
                let codeType: CodeType = if let attribute { .title(attribute.string) } else { .none }
                let text = if case let .text(text) = array.joined() { text } else { NSAttributedString(string: "") }
                elements.append(.code(.text(AttributedString(text)), codeType))
                
            case .hide(let attribute, let array):
                let subElements = convert(array)
                elements.append(.hide(subElements, Int(attribute?.string ?? "") ?? nil))
                
            case .img(let url):
                elements.append(.image(URL(string: url.string)!))
                
            case .cur(let array):
                let subElements = convert(array)
                elements.append(.notice(subElements, .curator))
                
            case .mod(let array):
                let subElements = convert(array)
                elements.append(.notice(subElements, .moderator))
                
            case .ex(let array):
                let subElements = convert(array)
                elements.append(.notice(subElements, .admin))
                
            case .snapback:
                fatalError("ПРОПУЩЕННЫЙ SNAPBACK")
                
            case .mergetime:
                fatalError("ПРОПУЩЕННЫЙ MERGETIME")
                
            case .attachment(let id):
                let id = Int(id.string.prefix(upTo: id.string.firstIndex(of: ":")!).dropFirst())!
                let attachment = attachments.first(where: { $0.id == id })!
                elements.append(.attachment(attachment))
                
            case .smile:
                fatalError("ПРОПУЩЕННЫЙ SMILE")
            }
        }
        return elements
    }
    
    private func parseQuoteAttributes(_ string: String?) -> QuoteType? {
        guard let string else { return nil }
        
        if string.first == "=" {
            let componentsQuote = string.components(separatedBy: "\"")
            if componentsQuote.count > 1 {
                let title = string.components(separatedBy: "\"")[1]
                return .title(title)
            }
            if string.contains("@") {
                let title = string.components(separatedBy: "@")[0]
                return .title(String(title.dropFirst()))
            }
            return .title(String(string.dropFirst()))
        } else {
            let pattern = /name=\"([^\"]+)\"(?: date=\"([^\"]+)\")?(?: post=(\d+))?/
            if let match = string.firstMatch(of: pattern) {
                let metadata = QuoteMetadata(
                    name: String(match.output.1),
                    date: match.output.2.map(String.init),
                    postId: match.output.3.flatMap { Int($0) }
                )
                return .metadata(metadata)
            }
        }
        
        return nil
    }
}
