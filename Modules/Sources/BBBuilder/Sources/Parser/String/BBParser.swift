import Foundation
import Models

public struct BBParser {
    
    public static func parse(text: String) -> [BBNode] {
        var parser = BBParser(text: text)
        return parser.parse()
    }
    
    private var tokenizer: BBTokenizer
    private var openingTags: [(tag: BBTag, attribute: String?)] = []
    
    private init(text: String) {
        tokenizer = BBTokenizer(string: text)
    }
    
    private mutating func parse() -> [BBNode] {
        var elements: [BBNode] = []
        
        while let token = tokenizer.nextToken() {
            // print("TOKEN: \(token)")
            if let tag = token.tag, tag.isContainerTag, !tag.canContainTags {
                elements.append(.text(token.description))
                continue
            }
            
            switch token {
            case let .openingTag(tag, attribute):
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
                
            default:
                elements.append(.text(token.description))
            }
        }
        
        let textElements: [BBNode] = openingTags.map { .text($0.tag.rawValue) }
        elements.insert(contentsOf: textElements, at: 0)
        openingTags.removeAll()
        
        return elements
    }
    
    private mutating func close(_ tag: BBTag, attribute: String?, elements: [BBNode]) -> BBNode? {
        var newElements = elements
        
        while openingTags.count > 0 {
            // (DEPRECATED) Берем последний тег и сравниваем с текущим, закрываем если совпадает, превращаем в текст если нет
//            let openingTag = openingTags.popLast()!
//            if openingTag.tag == tag {
//                break
//            } else {
//                newElements.insert(.text(openingTag.tag.rawValue), at: 0)
//            }
            
            // Ищем такой же тег в стеке, вместо последнего, на случай если теги помешаны местами
            if let index = openingTags.lastIndex(where: { $0.tag == tag }) {
                openingTags.remove(at: index)
                break
            } else {
                newElements.insert(.text(tag.rawValue), at: 0)
            }
        }
        
        return BBNode(tag: tag, attribute: attribute, children: newElements)
    }
}
