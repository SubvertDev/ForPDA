import UIKit
import ComposableArchitecture
import AnalyticsClient

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
    case hide(String?, [BBNode])
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
            // TODO: Fix after Sentry investingation
            let defaultUrl = URL(string: "https://4pda.to")!
            let urlString = attribute?.replacingOccurrences(of: "\"", with: "") ?? "https://4pda.to"
            // URL with url attribute are broken in quotes, so you need percentEncoding to make it fail instead of crash
            guard let string = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                @Dependency(\.analyticsClient) var analytics
                let error = NSError(domain: "BBNode", code: 10001, userInfo: ["urlString": urlString, "attribute": attribute ?? "nil"])
                analytics.capture(error)
                self = .url(defaultUrl, children)
                return
            }
            guard let url = URL(string: string) else {
                @Dependency(\.analyticsClient) var analytics
                let error = NSError(domain: "BBNode", code: 10002, userInfo: ["string": string, "urlString": urlString, "attribute": attribute ?? "nil"])
                analytics.capture(error)
                self = .url(defaultUrl, children)
                return
            }
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
        case .hide:    self = .hide(attribute, children)
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
