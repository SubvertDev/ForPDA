import Foundation

public enum BBTag: String {
    
    // Style tags
    case b
    case i
    case s
    case u
    case sup
    case sub
    case size
    case color
    case background
    case font
    case url
    case anchor
    case offtop

    // Container tags
    case center
    case left
    case right
    case justify
    case spoiler
    case list
    case quote
    case code
    case hide
    case cur
    case mod
    case ex
    
    // Pseudo container tags
    case snapback
    case mergetime
    case img
    
    // Self-closing tag (pseudo container?)
    case attachment
    case smile
    
    var isContainerTag: Bool {
        switch self {
        case .center, .left, .right, .justify, .spoiler, .list, .quote, .code, .hide, .cur, .mod, .ex, .snapback, .mergetime, .img, .attachment, .smile:
            return true
        default:
            return false
        }
    }
    
    var canContainTags: Bool {
        switch self {
        case .spoiler, .quote:
            return true
        default:
            return false
        }
    }
}
