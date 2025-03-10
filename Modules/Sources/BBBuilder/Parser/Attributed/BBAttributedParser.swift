//
//  BBParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.03.2025.
//

import UIKit

public struct BBAttributedParser {
    
    public static func parse(text: AttributedString) -> [BBContainerNode] {
        var parser = BBAttributedParser(text: text)
        return parser.parse()
    }
    
    private var attributedTokenizer: BBAttributedTokenizer
    private var openingTags: [(tag: BBTag, attribute: AttributedString?)] = []
    
    private init(text: AttributedString) {
        attributedTokenizer = BBAttributedTokenizer(string: text)
    }
    
    private mutating func parse() -> [BBContainerNode] {
        var elements: [BBContainerNode] = []
        
        while let token = attributedTokenizer.nextToken() {
            if let tag = token.tag, !tag.isContainerTag {
                print("НЕДОПУСТИМЫЙ ТЕГ \(tag)") // Скорее всего просто кривой тег
                elements.append(.text(NSAttributedString(token.description)))
                continue
            }
            
            switch token {
            case let .openingTag(tag, attribute):
                if tag == .attachment {
                    // Атачмент не имеет закрывающего тега, так что сразу добавляем напрямую
                    elements.append(.attachment(NSAttributedString(attribute!)))
                    continue
                }
                if tag == .smile {
                    // Смайл не имеет закрывающего тега, так что сразу добавляем напрямую
                    elements.append(.smile(NSAttributedString(attribute!)))
                    continue
                }
                openingTags.append((tag, attribute))
                elements.append(contentsOf: parse())
                
            case let .closingTag(tag) where openingTags.contains(where: { $0.tag == tag }):
                let attribute = openingTags.last(where: { $0.tag == tag })?.attribute
                guard let containerNode = close(tag, attribute: attribute, elements: elements) else {
                    fatalError("Не найдена открывающая пара")
                }
                return [containerNode]
                
            case let .text(text):
                elements.append(.text(NSAttributedString(text)))
                
            default: // E.g. закрывающий тег у которого нет пары
                elements.append(.text(NSAttributedString(token.description)))
            }
        }
        
        // TODO: Inject attributes instead of Import?
        let textElements: [BBContainerNode] = openingTags.map {
            .text(NSAttributedString(string: "[" + $0.tag.rawValue + "]", attributes: [
                .font: UIFont.defaultBBFont,
                .foregroundColor: UIColor(resource: .Labels.primary)
            ]))
        }
        elements.insert(contentsOf: textElements, at: 0)
        openingTags.removeAll()
        
        return elements
    }
    
    private mutating func close(_ tag: BBTag, attribute: AttributedString?, elements: [BBContainerNode]) -> BBContainerNode? {
        var newElements = elements
        
        while openingTags.count > 0 {
            // TODO: Апдейтнуть до BBParser варианта?
            let openingTag = openingTags.popLast()!
            if openingTag.tag == tag {
                break
            } else {
                newElements.insert(.text(NSAttributedString(string: tag.rawValue)), at: 0)
            }
        }
        
        return BBContainerNode(tag: tag, attribute: attribute, children: newElements)
    }
}
