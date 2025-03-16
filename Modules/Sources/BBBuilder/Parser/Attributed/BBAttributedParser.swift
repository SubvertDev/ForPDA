//
//  BBParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.03.2025.
//

import UIKit // TODO: Remove after UIFont removal
import Models

public struct BBAttributedParser {
    
    public static func parse(text: AttributedString, attachments: [Post.Attachment]) -> [BBContainerNode] {
        var parser = BBAttributedParser(text: text, attachments: attachments)
        return parser.parse()
    }
    
    private var attributedTokenizer: BBAttributedTokenizer
    private var attachments: [Post.Attachment]
    private var openingTags: [(tag: BBTag, attribute: NSAttributedString?)] = []
    
    private init(text: AttributedString, attachments: [Post.Attachment]) {
        attributedTokenizer = BBAttributedTokenizer(string: text)
        self.attachments = attachments
    }
    
    private mutating func parse() -> [BBContainerNode] {
        var elements: [BBContainerNode] = []
        
        while let token = attributedTokenizer.nextToken() {
            // print("ATTRIBUTED TOKEN: \(token)")
            if let tag = token.tag, !tag.isContainerTag {
                elements.append(.text(token.description))
                continue
            }
            
            switch token {
            case let .openingTag(tag, attribute):
                if tag == .attachment {
                    // Атачмент не имеет закрывающего тега, так что сразу добавляем напрямую
                    let attribute = attribute!
                    elements.append(.attachment(attribute))
                    let id = Int(attribute.string.prefix(upTo: attribute.string.firstIndex(of: ":")!).dropFirst())!
                    attachments.removeAll(where: { $0.id == id })
                    continue
                }
                if tag == .smile {
                    // Смайл не имеет закрывающего тега, так что сразу добавляем напрямую
                    elements.append(.smile(attribute!))
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
                elements.append(.text(text))
                
            default: // E.g. закрывающий тег у которого нет пары
                elements.append(.text(token.description))
            }
        }
        
        // TODO: Inject attributes instead of Import?
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.defaultBBFont,
            .foregroundColor: UIColor(resource: .Labels.primary)
        ]
        
        let textElements: [BBContainerNode] = openingTags.map {
            .text(NSAttributedString(string: "[" + $0.tag.rawValue + "]", attributes: attributes))
        }
        elements.insert(contentsOf: textElements, at: 0)
        openingTags.removeAll()
        
        // Adding attachments spoiler for all attachments that weren't used in post
        let imageNodes = attachments
            .filter { $0.type == .image }
            .map { BBContainerNode.attachment(NSAttributedString(string: "\"\($0.id):\($0.name)\"")) }
        if !imageNodes.isEmpty {
            elements.append(.spoiler(NSAttributedString(string: "Прикрепленные изображения", attributes: attributes), imageNodes))
        }
        
        attributes[.font] = UIFont.preferredFont(forBBCodeSize: 2).boldFont()
        
        // Adding files block for all attachments that weren't used in post
        let fileNodes = attachments
            .filter { $0.type == .file }
            .map { BBContainerNode.attachment(NSAttributedString(string: "\"\($0.id):\($0.name)\""))}
        if !fileNodes.isEmpty {
            elements.append(.text(NSAttributedString(string: "\n\nПрикрепленные файлы\n", attributes: attributes)))
            for (index, fileNode) in fileNodes.enumerated() {
                if index != 0 { elements.append(.text(NSAttributedString(string: " "))) }
                elements.append(fileNode)
            }
        }
        
        return elements
    }
    
    private mutating func close(_ tag: BBTag, attribute: NSAttributedString?, elements: [BBContainerNode]) -> BBContainerNode? {
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
