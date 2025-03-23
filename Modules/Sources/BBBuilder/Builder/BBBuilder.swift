import UIKit
import Models
import SharedUI
import UniformTypeIdentifiers
import ComposableArchitecture
import LoggerClient

func timeElapsed(from start: DispatchTime) -> String {
    let elapsedTime = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
    let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0
    return String(format: "%.2f ms", elapsedTimeInMilliSeconds)
}

struct ListInfo {
    var count = 0
    let type: BBContainerNode.ListType
}

public struct BBBuilder {
    
    // MARK: - Build Interface
    
    public static func build(text: String, attachments: [Post.Attachment] = []) -> [BBContainerNode] {
        let renderedText = AttributedString(BBRenderer().render(text: text))
        let builder = BBBuilder(attachments: attachments)
        let nodes = BBAttributedParser.parse(text: renderedText, attachments: attachments)
        return builder.mergeTextNodes(nodes)
    }
    
    // MARK: - Properties
    
    private var attachments: [Post.Attachment]
    
    // MARK: - Dependencies
    
    @Dependency(\.logger[.bbbuilder, false]) private var logger
    
    // MARK: - Init
    
    private init(attachments: [Post.Attachment]) {
        self.attachments = attachments
    }
    
    // MARK: - Implementation
    
    private func mergeTextNodes(_ nodes: [BBContainerNode], listInfo: ListInfo? = nil) -> [BBContainerNode] {
        var mergedNodes: [BBContainerNode] = []
        var listInfo = listInfo
        
        func hasPreviousNode(_ index: Int) -> Bool {
            return nodes[safe: index - 1] != nil
        }
        
        func hasNextNode(_ index: Int) -> Bool {
            return nodes[safe: index + 1] != nil
        }
        
        for (index, node) in nodes.enumerated() {
            // logger.info("NEW NODE: \(node)") // node doesnt conform to CustomStringConvertible
            
            let mutableText: NSMutableAttributedString
            if let last = mergedNodes.last, case let .text(lastText) = last {
                mutableText = NSMutableAttributedString(attributedString: lastText)
            } else {
                mutableText = NSMutableAttributedString(string: "")
            }
            
            switch node {
            case .text, .snapback, .mergetime, .smile:
                logger.info("In textable node")
                
                if listInfo != nil, node.isListTag {
                    logger.info("List tag, increasing counter")
                    listInfo?.count += 1
                }
                
                if mutableText.string.isEmpty {
                    var trimLeading = false
                    var trimTrailing = false
                    
                    if hasPreviousNode(index) {
                        if !nodes[index - 1].isTextable {
                            trimLeading = true
                        } else if nodes[index - 1].isMedia {
                            trimLeading = false
                        }
                    } else if !hasPreviousNode(index) {
                        trimLeading = true
                    }
                    logger.info("Trim leading: \(trimLeading)")
                    
                    if hasNextNode(index) {
                        logger.info("Has next node")
                        if !nodes[index + 1].isTextable {
                            logger.info("Next node is not textable")
                            trimTrailing = true
                        }
                        if nodes[index + 1].isMedia {
                            logger.info("Next node is media")
                            trimTrailing = false
                        }
                    } else if !hasNextNode(index) {
                        logger.info("There's no next node")
                        trimTrailing = true
                    }
                    logger.info("Trim trailing: \(trimTrailing)")
                    
                    let textNode = unwrap(
                        node: node,
                        with: mutableText,
                        listInfo: listInfo,
                        trimLeading: trimLeading,
                        trimTrailing: trimTrailing
                    )
                    if !textNode.isEmptyTrimmedText {
                        logger.info("Mutable text is empty, appending")
                        mergedNodes.append(textNode)
                    } else {
                        logger.info("Text node is empty after trimming, skipping")
                    }
                } else {
                    logger.info("Mutable text is not empty")
                    
                    let isNextNodeTextable = nodes[safe: index + 1]?.isTextable ?? false
                    let isNextNodeMedia = nodes[safe: index + 1]?.isMedia ?? false
                    if isNextNodeTextable || isNextNodeMedia {
                        logger.info("Next node is textable OR media, unwrapping")
                        var isAttachmentDelimeter = false
                        if case .attachment = nodes[safe: index - 1] {
                            isAttachmentDelimeter = true
                        }
                        mergedNodes[mergedNodes.count - 1] = unwrap(
                            node: node,
                            with: mutableText,
                            isAttachmentDelimeter: isAttachmentDelimeter,
                            listInfo: listInfo
                        )
                        if listInfo != nil,
                           case let .text(text) = nodes[safe: index - 1],
                           text.string == "[*]",
                           case let .text(text) = node,
                           text.string.last != "\n" {
                            logger.info("Didn't find newline character at the end of bullet, adding")
                            mutableText.mutableString.append("\n")
                        }
                    } else {
                        logger.info("Next node is not textable AND not media, unwrapping")
                        mergedNodes[mergedNodes.count - 1] = unwrap(
                            node: node,
                            with: mutableText,
                            listInfo: listInfo,
                            trimTrailing: true
                        )
                    }
                }
                
            case .img:
                logger.info("Image case")
                #warning("todo")
                mergedNodes.lastOrAppend = unwrap(node: node, with: mutableText)
                
            case let .attachment(attribute):
                logger.info("Attachment case")
                
                let attachmentId = Int(attribute.string.prefix(upTo: attribute.string.firstIndex(of: ":")!).dropFirst())!
                guard let attachmentIndex = attachments.firstIndex(where: { $0.id == attachmentId }) else {
                    logger.error("Didn't find attachment with id \(attachmentId), fallback to text")
                    let text = NSAttributedString(string: "[attachment=\(attribute.string)]", attributes: BBRenderer.defaultAttributes)
                    let textNode: BBContainerNode = .text(text)
                    mergedNodes.lastOrAppend = unwrap(node: textNode, with: mutableText)
                    continue
                }
                
                switch attachments[attachmentIndex].type {
                case .file:
                    logger.info("FILE attachment")
                    var isAttachmentDelimeter = false
                    if case let .text(text) = mergedNodes.last, text.string.last != "\n" {
                        isAttachmentDelimeter = true
                    }
                    let textNode = unwrap(node: node, with: mutableText, isAttachmentDelimeter: isAttachmentDelimeter)
                    if !textNode.isEmptyText {
                        mergedNodes.lastOrAppend = textNode
                    } else {
                        fatalError("File attachment textNode is empty")
                    }
                    continue
                    
                case .image:
                    break // TODO: Move image attachment below here
                }
                
                logger.info("IMAGE attachment")
                if hasPreviousNode(index) {
                    logger.info("Has previous node")
                    if nodes[index - 1].isTextable {
                        logger.info("Previous node is textable")
                        if nodes[index - 1].hasOnlyOneSpace {
                            logger.info("Previous node is only one space")
                            if let lastMergedNode = mergedNodes.last, case .text = lastMergedNode {
                                logger.info("Last merged node was text, unwrapping")
                                mergedNodes[mergedNodes.count - 1] = unwrap(node: node, with: mutableText)
                            } else {
                                logger.info("Last merged node wasn't text, appending")
                                mergedNodes.append(node)
                            }
//                            mergedNodes.append(node)
                        } else if nodes[index - 1].isEmptyTrimmedText {
                            logger.info("Previous node is empty after trimming text, appending")
                            mergedNodes.append(node)
                        } else {
                            logger.info("Previous node is NOT single whitespace, unwrapping")
                            mergedNodes.lastOrAppend = unwrap(node: node, with: mutableText)
                        }
                    } else {
                        logger.info("Previous node is textable OR not media, checking next node")
                        checkNextNode(hasPreviousNode: true)
                    }
                } else {
                    logger.info("Doesn't have previous node")
                    checkNextNode(hasPreviousNode: false)
                }
                
                func checkNextNode(hasPreviousNode: Bool) {
                    if hasNextNode(index) {
                        logger.info("Has next node")
                        if nodes[index + 1].isTextable {
                            logger.info("Next node is textable")
                            if nodes[index + 1].startsWithNewline || nodes[index + 1].startsWithSpace {
                                logger.info("Next node starts with newline or space, appending")
                                mergedNodes.append(node)
                            } else if hasPreviousNode {
                                logger.info("Has previous node, unwrapping")
                                mergedNodes[mergedNodes.count - 1] = unwrap(node: node, with: mutableText)
                            } else {
                                logger.info("Next is not newline/space and has no previous node, appending unwrapped")
                                mergedNodes.append(unwrap(node: node, with: mutableText))
                            }
                        } else {
                            logger.info("Next node is non textable, appending")
                            mergedNodes.append(node)
                        }
                    } else {
                        logger.info("Has no next node, appending")
                        mergedNodes.append(node)
                    }
                }
                
            case .center(let array):
                mergedNodes.append(.center(mergeTextNodes(array)))
                
            case .left(let array):
                mergedNodes.append(.left(mergeTextNodes(array)))
                
            case .right(let array):
                mergedNodes.append(.right(mergeTextNodes(array)))
                
            case .justify(let array):
                mergedNodes.append(.justify(mergeTextNodes(array)))
                
            case .spoiler(let attributed, let array):
                mergedNodes.append(.spoiler(attributed, mergeTextNodes(array)))
                
            case .quote(let attributed, let array):
                mergedNodes.append(.quote(attributed, mergeTextNodes(array)))
                
            case .list(let type, let array):
                mergedNodes.append(.list(type, mergeTextNodes(array, listInfo: ListInfo(type: type))))
                
            case .code(let title, let array):
                mergedNodes.append(.code(title, mergeTextNodes(array)))
                
            case .hide(let attribute, let array):
                mergedNodes.append(.hide(attribute, mergeTextNodes(array)))
                
            case .cur(let array):
                mergedNodes.append(.cur(mergeTextNodes(array)))
                
            case .mod(let array):
                mergedNodes.append(.mod(mergeTextNodes(array)))
                
            case .ex(let array):
                mergedNodes.append(.ex(mergeTextNodes(array)))
            }
        }
        
        return mergedNodes
    }
    
    // MARK: - Unwrap
    
    /// Превращает text / snapback / mergetime / img / attachment / smile в текстовую ноду
    private func unwrap(
        node: BBContainerNode,
        with combinedText: NSAttributedString,
        isFirst: Bool = false,
        isAttachmentDelimeter: Bool = false,
        listInfo: ListInfo? = nil,
        trimLeading: Bool = false,
        trimTrailing: Bool = false
    ) -> BBContainerNode {
        return unwrap(
            node: node,
            with: NSMutableAttributedString(attributedString: combinedText),
            isFirst: isFirst,
            isAttachmentDelimeter: isAttachmentDelimeter,
            trimLeading: trimLeading,
            trimTrailing: trimTrailing
        )
    }
    
    /// Превращает text / snapback / mergetime / img / attachment / smile в текстовую ноду
    private func unwrap(
        node: BBContainerNode,
        with combinedText: NSMutableAttributedString,
        isFirst: Bool = false,
        isAttachmentDelimeter: Bool = false,
        listInfo: ListInfo? = nil,
        trimLeading: Bool = false,
        trimTrailing: Bool = false
    ) -> BBContainerNode {
        // TODO: Вынести isFirst обработчики
        switch node {
        case .text(let text):
            let mutableString = NSMutableAttributedString(
                attributedString: text
                    .trimmingNewlines(leading: trimLeading, trailing: trimTrailing)
                    .replacingOccurrences(of: "&#91;", with: "[")
                    .replacingOccurrences(of: "&#93;", with: "]")
            )
            if isAttachmentDelimeter {
                if mutableString.string.prefix(1) == " " {
                    mutableString.replaceCharacters(in: NSRange(location: 0, length: 1), with: "\n")
                }
            }
            if let listInfo {
                mutableString.replaceListTags(for: listInfo)
            }
            if isFirst {
                return .text(mutableString)
            } else {
                combinedText.append(mutableString)
                return .text(combinedText)
            }
            
        case .snapback(let postId):
            let image = UIImage(resource: .snapback)
            let attachment = AsyncTextAttachment(image: image, displaySize: CGSize(width: 16, height: 16))
            Task { @MainActor [postId = postId.string] in image.accessibilityHint = postId }
            let textWithAttachment = NSMutableAttributedString(attachment: attachment)
            textWithAttachment.addAttributes([.baselineOffset: -2.5], range: NSRange(location: 0, length: textWithAttachment.length))
            if isFirst {
                return .text(textWithAttachment)
            } else {
                combinedText.append(textWithAttachment)
                return .text(combinedText)
            }
            
        case .mergetime(let time):
            let date = Date(timeIntervalSince1970: TimeInterval(time.string)!).formatted()
            let textWithDate = NSAttributedString(string: date, attributes: time.attributes(at: 0, effectiveRange: nil))
            if isFirst {
                return .text(textWithDate)
            } else {
                combinedText.append(textWithDate)
                return .text(combinedText)
            }
            
        case .img(let url):
            let url = URL(string: url.string)!
            let attachment = AsyncTextAttachment(attachmentUrl: url, delegate: nil)
            attachment.image = UIImage.placeholder(color: .lightGray, size: CGSize(width: 32, height: 32)) // TODO: Skeleton loader
            let textWithAttachment = NSAttributedString(attachment: attachment)
            if isFirst {
                return .text(textWithAttachment)
            } else {
                combinedText.append(textWithAttachment)
                return .text(combinedText)
            }
            
        case .attachment(let attachmentId):
            let id = Int(attachmentId.string.prefix(upTo: attachmentId.string.firstIndex(of: ":")!).dropFirst())!
            
            let attachment = attachments.first(where: { $0.id == id })!
            let attachmentString: NSAttributedString
            
            if attachment.type == .image {
                let asyncAttachment = AsyncTextAttachment(attachmentUrl: attachment.metadata!.url)
                asyncAttachment.image = UIImage.placeholder(color: .gray, size: CGSize(width: 32, height: 32)) // TODO: Skeleton loader
                attachmentString = NSAttributedString(attachment: asyncAttachment)
            } else {
                let image = UIImage(systemSymbol: .arrowDownDoc).withTintColor(.tintColor)//, withConfiguration: config)
                let textAttachment = AsyncTextAttachment(image: image)//, displaySize: CGSize(width: 16, height: 16))
                Task { @MainActor in textAttachment.accessibilityHint = String(id) }
                
                let mutableString = NSMutableAttributedString(attachment: textAttachment)
                mutableString.addAttribute(.baselineOffset, value: -3, range: .fullRange(of: mutableString))
                
                let attachmentName = NSAttributedString(string: attachment.name)
                mutableString.append(attachmentName)
                mutableString.addAttribute(.link, value: URL(string: "link://\(id)")!, range: .fullRange(of: mutableString))
                
                mutableString.append(NSAttributedString(string: " (\(attachment.sizeString))", attributes: [.foregroundColor: UIColor(resource: .Labels.primary)]))
                mutableString.addAttribute(.font, value: UIFont.defaultBBFont, range: .fullRange(of: mutableString))
                
                if let downloadCount = attachment.downloadCount {
                    let info = " Cкачиваний: \(downloadCount)"
                    mutableString.append(NSAttributedString(string: info, attributes: [
                        .font: UIFont.preferredFont(forBBCodeSize: 1),
                        .foregroundColor: UIColor(resource: .Labels.teritary)
                    ]))
                }
                
                if isAttachmentDelimeter {
                    mutableString.insert(NSAttributedString(string: "\n"), at: 0)
                }
                                
                attachmentString = mutableString
            }

            if isFirst {
                return .text(attachmentString)
            } else {
                combinedText.append(attachmentString)
                return .text(combinedText)
            }
            
        case .smile(let smile):
            let smile = BBSmile.list.first(where: { $0.resourceName == smile.string })!
            let image = UIImage(named: smile.resourceName)!.scaled(to: CGFloat(smile.width))
            let attachment = NSTextAttachment(image: image)
            let textWithSmile = NSMutableAttributedString(attachment: attachment)
            if isFirst {
                return .text(textWithSmile)
            } else {
                combinedText.append(textWithSmile)
                return .text(combinedText)
            }
            
        default:
            fatalError("НЕИЗВЕСТНЫЙ ТЕКСТОВЫЙ ТЕГ")
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    var lastOrAppend: Element? {
        get { last }
        set {
            if let newValue = newValue {
                if isEmpty {
                    append(newValue)
                } else {
                    self[count - 1] = newValue
                }
            }
        }
    }
}

extension NSRange {
    static func fullRange(of string: NSMutableAttributedString) -> NSRange {
        return NSRange(location: 0, length: string.length)
    }
    
    static func fullRange(of string: NSAttributedString) -> NSRange {
        return NSRange(location: 0, length: string.length)
    }
}

extension NSAttributedString {

    // TODO: Revisit performance-wise
    func trimmingNewlines(leading: Bool = true, trailing: Bool = true) -> NSAttributedString {
        if !leading && !trailing { return self }
        
        let mutableAttributedString = NSMutableAttributedString(attributedString: self)
        let characterSet = CharacterSet.newlines

        // Trim leading newlines
        if leading {
            while mutableAttributedString.string.first.map({ characterSet.contains($0.unicodeScalars.first!) }) ?? false {
                mutableAttributedString.deleteCharacters(in: NSRange(location: 0, length: 1))
            }
        }

        // Trim trailing newlines
        if trailing {
            while mutableAttributedString.string.last.map({ characterSet.contains($0.unicodeScalars.first!) }) ?? false {
                mutableAttributedString.deleteCharacters(in: NSRange(location: mutableAttributedString.length - 1, length: 1))
            }
        }

        return mutableAttributedString
    }
    
    // TODO: Revisit performance-wise
    func replacingOccurrences(of target: String, with replacement: String) -> NSAttributedString {
        let mutableCopy = NSMutableAttributedString(attributedString: self)
        var searchRange = NSRange(location: 0, length: mutableCopy.length)
        
        while let foundRange = mutableCopy.string.range(of: target, options: [], range: Range(searchRange, in: mutableCopy.string)) {
            let nsRange = NSRange(foundRange, in: mutableCopy.string)
            mutableCopy.replaceCharacters(in: nsRange, with: replacement)
            
            let newLocation = nsRange.location + (replacement as NSString).length
            searchRange = NSRange(location: newLocation, length: mutableCopy.length - newLocation)
        }
        
        return mutableCopy
    }
}

extension NSMutableAttributedString {
    func replaceListTags(for info: ListInfo) {
        let target = "[*]"
        
        while let range = string.range(of: target) {
            let nsRange = NSRange(range, in: string)
            replaceCharacters(in: nsRange, with: getReplacement(for: info.type, at: info.count))
        }
    }
    
    private func getReplacement(for type: BBContainerNode.ListType, at index: Int) -> String {
        switch type {
        case .bullet:
            return "• "
        case .numeric:
            return "\(index). "
        case .alphabet:
            return "\(Character(UnicodeScalar(96 + index)!)). "
        case .romanBig:
            return "\(toRoman(index).uppercased()). "
        case .romanSmall:
            return "\(toRoman(index).lowercased()). "
        }
    }
    
    private func toRoman(_ num: Int) -> String {
        let values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        let symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
        
        var result = ""
        var number = num
        
        for (value, symbol) in zip(values, symbols) {
            while number >= value {
                result += symbol
                number -= value
            }
        }
        return result
    }
}

// MARK: - Helpers

private extension UIImage {
    func scaled(to maxSize: CGFloat) -> UIImage {
        let aspectRatio: CGFloat = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * aspectRatio, height: size.height * aspectRatio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        }
    }
}
