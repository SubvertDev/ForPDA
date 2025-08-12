import Foundation

public struct BBTokenizer {
    
    // MARK: - Stored Properties
    
    private let input: String.UnicodeScalarView
    private var currentIndex: String.UnicodeScalarView.Index
    
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
    
    public init(string: String) {
        self.input = string.unicodeScalars
        self.currentIndex = string.unicodeScalars.startIndex
    }
    
    // MARK: - Implementation
    
    public mutating func nextToken() -> BBToken? {
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
                    let string = String(input[tagStartIndex..<currentIndex])
                    let tag = BBTag(rawValue: string.lowercased())
                    if let tag {
                        advanceIndex()
                        return .closingTag(tag)
                    } else {
                        advanceIndex()
                        let string = String(input[parseStartIndex..<currentIndex])
                        return .text(string)
                    }
                } else {
                    fatalError("Tokenizer1")
                }
            } else {
                // Открывающий тег
                let tagStartIndex = currentIndex
                var tagAttribute: String?
                
                // Ищем ближайшие делители "]" "=" " "
                while currentIndex < input.endIndex, input[currentIndex] != .closingBracket, input[currentIndex] != .equal, input[currentIndex] != .space {
                    advanceIndex()
                }
                
                let string = String(input[tagStartIndex..<currentIndex])
                guard let tag = BBTag(rawValue: string.lowercased()) else {
                    // Если мы встретили открывающий тег который не закрылся до конца сообщения, то advance делать не надо
                    if currentIndex < input.endIndex {
                        advanceIndex()
                    }
                    let string = String(input[parseStartIndex..<currentIndex])
                    return .text(string)
                }
                
                // Ищем ближайший знак равенства "=" или пробела " "
                if currentIndex < input.endIndex, input[currentIndex] == .equal || input[currentIndex] == .space {
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
                                let attributeTextWithTags = String(input[attributeStartIndex..<currentIndex])
                                advanceIndex()
                                return .openingTag(tag == .spoiler ? .spoiler : .quote, attributeTextWithTags)
                            }
                            advanceIndex()
                        }
                    } else {
                        // Ищем ближайшую закрывающую скобку "]"
                        while currentIndex < input.endIndex, input[currentIndex] != .closingBracket {
                            advanceIndex()
                        }
                        
                        // Создаем атрибут начиная с "="/" " и заканчивая "]"
                        tagAttribute = String(input[attributeStartIndex..<currentIndex])
                    }
                }
                
                // Ищем ближайшую закрывающую скобку "]", записываем как открывающий тег
                if currentIndex < input.endIndex, input[currentIndex] == .closingBracket {
                    advanceIndex()
                    return .openingTag(tag, tagAttribute)
                } else {
                    fatalError("Tokenizer2")
                }
            }
        } else {
            let textStartIndex = currentIndex
            scanUntil(.openingBracket)
            let text = String(input[textStartIndex..<currentIndex])
            return .text(text)
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

extension UnicodeScalar {
    static let space = UnicodeScalar(" ")
    static let equal = UnicodeScalar("=")
    static let openingBracket = UnicodeScalar("[")
    static let closingBracket = UnicodeScalar("]")
    static let colon = UnicodeScalar(":")
}

extension CharacterSet {
    static let delimeters = CharacterSet(charactersIn: "]=: ")
}
