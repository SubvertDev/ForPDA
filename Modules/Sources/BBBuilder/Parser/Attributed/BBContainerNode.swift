//
//  BBContainerNode.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.03.2025.
//

import Foundation

public enum BBContainerNode: Equatable {
    
    case text(NSAttributedString)
    case center([BBContainerNode])
    case left([BBContainerNode])
    case right([BBContainerNode])
    case justify([BBContainerNode])
    case list(ListType, [BBContainerNode])
    case spoiler(NSAttributedString?, [BBContainerNode])
    case quote(NSAttributedString?, [BBContainerNode])
    case code(NSAttributedString?, [BBContainerNode])
    case hide(NSAttributedString?, [BBContainerNode])
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
//        case .text, .snapback, .mergetime, .img, .attachment, .smile:
        case .text, .snapback, .mergetime, .smile:
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
    
//    public var isFileAttachment: Bool {
//        if case let .attachment(attribute) = self {
//            let fileExtension = String(attribute.string.suffix(from: attribute.string.lastIndex(of: ".")!).dropFirst().dropLast())
//            return !isImageType(fileExtension)
//        }
//        return false
//    }
    
    public var isEmptyTrimmedText: Bool {
        if case let .text(text) = self {
            return text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    public var isEmptyText: Bool {
        if case let .text(text) = self {
            return text.string.isEmpty
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
    
    /// Для разделения аттачей по строкам
    public var hasOnlyOneSpace: Bool {
        if case let .text(text) = self {
            return text.string == " "
        }
        return false
    }
    
    public var startsWithNewline: Bool {
        if case let .text(text) = self {
            return text.string.prefix(1) == "\n"
        }
        return false
    }
    
    public var startsWithSpaceOrNewline: Bool {
        return startsWithSpace || startsWithNewline
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
        case .hide:    self = .hide(attribute, children)
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
