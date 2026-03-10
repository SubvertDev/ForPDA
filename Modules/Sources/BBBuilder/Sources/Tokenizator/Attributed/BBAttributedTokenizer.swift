import SwiftUI

public struct BBAttributedTokenizer {
    
    // MARK: - Stored Properties
    
    private let original: AttributedString
    private let input: AttributedString.UnicodeScalarView
    private var currentIndex: AttributedString.UnicodeScalarView.Index
    
    // MARK: - Computed Properties
    
    private var currentChar: UnicodeScalar? {
        guard currentIndex < input.endIndex else { return nil }
        return input[currentIndex]
    }
    
    private var previousChar: UnicodeScalar? {
        guard currentIndex > input.startIndex else { return nil }
        let index = input.index(before: currentIndex)
        return input[index]
    }
    
    private var nextChar: UnicodeScalar? {
        guard currentIndex < input.endIndex else { return nil }
        let index = input.index(after: currentIndex)
        guard index < input.endIndex else { return nil }
        return input[index]
    }
    
    // MARK: - Init
    
    public init(string: AttributedString) {
        self.original = string
        self.input = string.unicodeScalars
        self.currentIndex = string.unicodeScalars.startIndex
    }
    
    // MARK: - Implementation
    
    public mutating func nextToken() -> BBAttributedToken? {
        // Проверяем есть ли у нас текущий символ, если нет, то текст кончился
        guard let currentChar else { return nil }
        if currentChar == "[" {
            // Начинаем парсить потенциально открывающий/закрывающий тег
            let parseStartIndex = currentIndex
            advanceIndex()
            
            if currentIndex < input.endIndex, input[currentIndex] == "/" {
                // Закрывающий тег
                advanceIndex()
                let tagStartIndex = currentIndex
                // ]
                while currentIndex < input.endIndex, input[currentIndex] != .closingBracket {
                    advanceIndex()
                }
                
                if currentIndex < input.endIndex {
                    let string = input[tagStartIndex..<currentIndex].toString()
                    let tag = BBTag(rawValue: string)
                    if let tag {
                        advanceIndex()
                        return .closingTag(tag)
                    } else {
                        advanceIndex()
                        let string = AttributedString(original[parseStartIndex..<currentIndex])
                        return .text(NSAttributedString(string))
                    }
                } else {
                    print("TokenizerA1")
                }
            } else {
                // Открывающий тег
                let tagStartIndex = currentIndex
                var tagAttribute: String?
                
                // ] =
                while currentIndex < input.endIndex, input[currentIndex] != .closingBracket, input[currentIndex] != .equal {
                    advanceIndex()
                }
                
                let string = input[tagStartIndex..<currentIndex].toString()
                guard let tag = BBTag(rawValue: string) else {
                    // Если мы встретили открывающий тег который не закрылся до конца сообщения, то advance делать не надо
                    if currentIndex < input.endIndex {
                        advanceIndex()
                    }
                    let string = AttributedString(original[parseStartIndex..<currentIndex])
                    return .text(NSAttributedString(string))
                }
                
                // Ищем ближайший знак равенства "=" или пробела " "
                if currentIndex < input.endIndex, input[currentIndex] == .equal {
                    // Тег с атрибутами e.g. [color=red] или [quote name="Govnuk"]
                    advanceIndex()
                    
                    let attributeStartIndex = currentIndex
                    
                    if tag == .spoiler || tag == .quote {
                        // Атрибут спойлера/цитаты может иметь свои бб коды и должен распарситься дополнительно
                        // Тег заканчивается на первой закрывающей скобки без открывающей пары
                        var tagsBalance = 0
                        while currentIndex < input.endIndex {
                            if input[currentIndex] == .openingBracket {
                                tagsBalance += 1
                            } else if input[currentIndex] == .closingBracket {
                                tagsBalance -= 1
                            }
                            if tagsBalance < 0 {
                                let attributeTextWithTags = AttributedString(original[attributeStartIndex..<currentIndex])
                                advanceIndex()
                                return .openingTag(tag == .spoiler ? .spoiler : .quote, NSAttributedString(attributeTextWithTags))
                            }
                            advanceIndex()
                        }
                    } else {
                        // Ищем ближайшую закрывающую скобку "]"
                        while currentIndex < input.endIndex, input[currentIndex] != .closingBracket {
                            advanceIndex()
                        }
                        
                        // Создаем атрибут начиная с "=" и заканчивая "]"
                        tagAttribute = input[attributeStartIndex..<currentIndex].toString()
                    }
                }
                
                // Ищем ближайшую закрывающую скобку "]", записываем как открывающий тег
                if currentIndex < input.endIndex, input[currentIndex] == .closingBracket {
                    advanceIndex()
                    return .openingTag(tag, tagAttribute.map { NSAttributedString(string: $0) })
                } else {
                    print("TokenizerA2")
                }
            }
        } else {
            let textStartIndex = currentIndex
            return scanForText(textStartIndex: textStartIndex)
        }
        
        return nil
    }
    
    
    private mutating func scanForText(textStartIndex: AttributedString.UnicodeScalarView.Index, layer: Int = 0) -> BBAttributedToken? {
        // FIXME: Fix for MIUI page 6, investigate later
        guard layer < 160 else { return .text(NSAttributedString(AttributedString(original[textStartIndex..<currentIndex]))) }
        
        scanUntil { $0 == .openingBracket || $0 == .colon }
        
        guard currentIndex < input.endIndex else {
            // TODO: Hotfix, revisit
            let text = AttributedString(original[textStartIndex..<currentIndex])
            return .text(NSAttributedString(text))
        }
        
        if input[currentIndex] == .openingBracket {
            let text = AttributedString(original[textStartIndex..<currentIndex])
            return .text(NSAttributedString(text))
        } else if input[currentIndex] == .colon {
            if let smile = scanForSmile() {
                if textStartIndex == currentIndex {
                    for _ in 0..<smile.code.count {
                        advanceIndex()
                    }
                    return .openingTag(.smile, NSAttributedString(string: smile.resourceName))
                } else {
                    let text = AttributedString(original[textStartIndex..<currentIndex])
                    return .text(NSAttributedString(text))
                }
            } else {
                advanceIndex()
                return scanForText(textStartIndex: textStartIndex, layer: layer + 1)
            }
        } else {
            fatalError("Kak?")
        }
    }
    
    private mutating func scanForSmile() -> BBSmile? {
        if input.index(after: currentIndex) < input.endIndex,
            input[input.index(after: currentIndex)] == "\n" {
            return nil
        }
        
        var smileIndex = 0
        while true {
            let smile = BBSmile.list[smileIndex]
            if smile.code.count <= input[currentIndex..<input.endIndex].count {
                if smile.code == input[currentIndex..<input.index(currentIndex, offsetBy: smile.code.count)].toString() {
                    return smile
                }
            }
            
            smileIndex += 1
            if smileIndex >= BBSmile.list.count {
                break
            }
        }
                
        return nil
    }
    
    private mutating func scanUntil(_ unicodeScalar: UnicodeScalar) {
        while currentIndex < input.endIndex && (unicodeScalar != input[currentIndex]) {
            advanceIndex()
        }
    }

    private mutating func scanUntil(_ predicate: (UnicodeScalar) -> Bool) {
        while currentIndex < input.endIndex && !predicate(input[currentIndex]) {
            advanceIndex()
        }
    }
    
    private mutating func advanceIndex() {
        currentIndex = input.index(after: currentIndex)
    }
}

extension BidirectionalCollection where Element == UnicodeScalar {
    func toString() -> String {
        return String(String.UnicodeScalarView(self)) // TODO: Revisit performance-wise
    }
    
    func toAttributedString() -> AttributedString {
        return AttributedString(map { Character($0) }) // TODO: Revisit performance-wise
    }
}
