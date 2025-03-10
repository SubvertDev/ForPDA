import Foundation

public enum BBToken: Equatable {
    case openingTag(BBTag, String?)
    case closingTag(BBTag)
    case text(String)
}

public extension BBToken {
    var description: String {
        switch self {
        case let .openingTag(tag, attribute):
            if let attribute {
                return "[\(tag)=\(attribute)]"
            } else {
                return "[\(tag)]"
            }
        case let .closingTag(tag):
            return "[/\(tag)]"
        case let .text(text):
            return text
        }
    }
    
    var tag: BBTag? {
        switch self {
        case .openingTag(let tag, _), .closingTag(let tag):
            return tag
        case .text:
            return nil
        }
    }
}

public enum BBAttributedToken: Equatable {
    case openingTag(BBTag, AttributedString?)
    case closingTag(BBTag)
    case text(AttributedString)
}

public extension BBAttributedToken {
    var description: AttributedString {
        switch self {
        case let .openingTag(tag, attribute):
            if let attribute {
                return AttributedString("[\(tag)=\(attribute)]")
            } else {
                return AttributedString("[\(tag)]")
            }
        case let .closingTag(tag):
            return AttributedString("[/\(tag)]")
        case let .text(text):
            return text
        }
    }
    
    var tag: BBTag? {
        switch self {
        case .openingTag(let tag, _), .closingTag(let tag):
            return tag
        case .text:
            return nil
        }
    }
}

private extension String {
    func attributed() -> AttributedString {
        return AttributedString(self)
    }
}
