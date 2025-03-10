import UIKit

public enum BBContainerNode {
    
    case text(NSAttributedString)
    case center([BBContainerNode])
    case left([BBContainerNode])
    case right([BBContainerNode])
    case justify([BBContainerNode])
    case list(ListType, [BBContainerNode])
    case spoiler(NSAttributedString?, [BBContainerNode])
    case quote(NSAttributedString?, [BBContainerNode])
    case code(NSAttributedString?, [BBContainerNode])
    case hide([BBContainerNode])
    case cur([BBContainerNode])
    case mod([BBContainerNode])
    case ex([BBContainerNode])
    case img(NSAttributedString) // URL
    case snapback(NSAttributedString) // ID (Int)
    case mergetime(NSAttributedString) // TimeInterval
    case attachment(NSAttributedString) // ID (Int)
    case smile(NSAttributedString) // String
    
    public enum ListType: String {
        case bullet = ""
        case numeric = "1"
        case alphabet = "A"
        case romanBig = "I"
        case romanSmall = "i"
    }
    
    public var isTextable: Bool {
        switch self {
        case .text, .snapback, .mergetime, .img, .attachment, .smile:
            return true
        default:
            return false
        }
    }
    
    public var isMedia: Bool {
        switch self {
        case .img, .attachment:
            return true
        default:
            return false
        }
    }
    
//    public var isTextAndEmpty: Bool {
//        if case let .text(text) = self {
//            if text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                return true
//            }
//        }
//        return false
//    }
    
    /// Обсуждение клиента, спойлер с тремя картинками, между ними пробел
    public var isEmptyText: Bool {
        if case let .text(text) = self {
            return text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    /// Для разделения аттачей по строкам
    public var startsWithSpace: Bool {
        if case let .text(text) = self {
            return text.string.prefix(1) == " "
        }
        return false
    }
    
    init?(tag: BBTag, attribute: AttributedString?, children: [BBContainerNode]) {
        self.init(tag: tag, attribute: attribute.map { NSAttributedString($0) }, children: children)
    }
    
    init?(tag: BBTag, attribute: NSAttributedString?, children: [BBContainerNode]) {
        switch tag {
        case .center:  self = .center(children)
        case .left:    self = .left(children)
        case .right:   self = .right(children)
        case .justify: self = .justify(children)
        case .list:    self = .list(ListType(rawValue: attribute?.string ?? "")!, children)
        case .spoiler: self = .spoiler(attribute, children)
        case .quote:   self = .quote(attribute, children)
        case .code:    self = .code(attribute, children)
        case .hide:    self = .hide(children)
        case .cur:     self = .cur(children)
        case .mod:     self = .mod(children)
        case .ex:      self = .ex(children)
        case .snapback:
            // TODO: Доделать
            if case let .text(text) = children.first! {
                self = .snapback(text)
            } else {
                fatalError("BBContainerNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ SNAPBACK")
            }
        case .mergetime:
            if case let .text(text) = children.first! {
                self = .mergetime(text)
            } else {
                fatalError("BBContainerNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ MERGETIME")
            }
        case .img:
            if case let .text(text) = children.first! {
                self = .img(text)
            } else {
                fatalError("BBContainerNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ IMG")
            }
        case .attachment:
            if case let .text(text) = children.first! {
                self = .attachment(text)
            } else {
                fatalError("BBContainerNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ IMG")
            }
        case .smile:
            if case let .text(text) = children.first! {
                self = .smile(text)
            } else {
                fatalError("BBContainerNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ SMILE")
            }
        default:
            return nil
        }
    }
}

public enum BBNode {
    // Style nodes
    case text(String)
    case bold([BBNode])
    case italic([BBNode])
    case underline([BBNode])
    case strikethrough([BBNode])
    case sup([BBNode])
    case sub([BBNode])
    case size(_ size: Int?, [BBNode])
    case color(_ color: String, [BBNode]) // either word or hex
    case background(_ color: String, [BBNode]) // either word or hex
    case font(_ name: String, [BBNode])
    case url(_ url: URL, [BBNode])
    case anchor([BBNode])
    case offtop([BBNode])
    
    // Container nodes
    case center([BBNode])
    case left([BBNode])
    case right([BBNode])
    case justify([BBNode])
    case list(BBContainerNode.ListType, [BBNode])
    case spoiler(String?, [BBNode])
    case quote(String?, [BBNode])
    case code(String?, [BBNode])
    case hide([BBNode])
    case cur([BBNode])
    case mod([BBNode])
    case ex([BBNode])
    
    // Pseudo container nodes
    case snapback(String)
    case mergetime(String)
    case img(String)
    
    // Self-closing tags (pseudo containers?)
    case attachment(String)
    case smile(String)
    
    var isContainerNode: Bool {
        switch self {
        case .center, .left, .right, .justify, .spoiler, .list, .quote, .code, .hide, .cur, .mod, .ex, .snapback, .mergetime, .img, .attachment:
            return true
        default:
            return false
        }
    }
}

public extension BBNode {
    init?(tag: BBTag, attribute: String?, children: [BBNode]) {
        switch tag {
            // Styles
        case .b:     self = .bold(children)
        case .i:     self = .italic(children)
        case .u:     self = .underline(children)
        case .s:     self = .strikethrough(children)
        case .sub:   self = .sub(children)
        case .sup:   self = .sup(children)
        case .size:  self = .size(Int(attribute ?? ""), children)
        case .color: self = .color(attribute!, children)
        case .background: self = .background(attribute!, children)
        case .font:  self = .font(attribute!, children)
        case .url:
            let urlString = attribute?.replacingOccurrences(of: "\"", with: "") ?? "4pda.to"
            // URL with url attribute are broken in quotes, so you need percentEncoding to make it fail instead of crash
            let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            self = .url(url, children) // TODO: Make proper url handling
        case .anchor: self = .anchor(children)
        case .offtop: self = .offtop(children)
        
            // Containers
        case .center:  self = .center(children)
        case .left:    self = .left(children)
        case .right:   self = .right(children)
        case .justify: self = .justify(children)
        case .list:    self = .list(BBContainerNode.ListType(rawValue: attribute ?? "")!, children)
        case .spoiler: self = .spoiler(attribute, children)
        case .quote:   self = .quote(attribute, children)
        case .code:    self = .code(attribute, children)
        case .hide:    self = .hide(children)
        case .cur:     self = .cur(children)
        case .mod:     self = .mod(children)
        case .ex:      self = .ex(children)
        case .snapback:
            if case let .snapback(postId) = children.first! {
                self = .snapback(postId)
            } else {
                fatalError("BBNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ SNAPBACK")
            }
        case .mergetime:
            if case let .mergetime(time) = children.first! {
                self = .mergetime(time)
            } else {
                fatalError("BBNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ MERGETIME")
            }
        case .img:
            if case let .img(time) = children.first! {
                self = .img(time)
            } else {
                fatalError("BBNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ IMG")
            }
        case .attachment:
            if case let .attachment(time) = children.first! {
                self = .attachment(time)
            } else {
                fatalError("BBNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ ATTACHMENT")
            }
        case .smile:
            if case let .smile(time) = children.first! {
                self = .smile(time)
            } else {
                fatalError("BBNode НЕ ПОЛУЧИЛОСЬ СОЗДАТЬ SMILE")
            }
        }
    }
}
