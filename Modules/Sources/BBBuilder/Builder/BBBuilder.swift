import UIKit
import Models
import SharedUI

func timeElapsed(from start: DispatchTime) -> String {
    let elapsedTime = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
    let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0
    return String(format: "%.2f ms", elapsedTimeInMilliSeconds)
}

public struct BBBuilder {
    
    // MARK: - Build Interface
    
    public static func build(text: String, attachments: [Post.Attachment]) -> [BBContainerNode] {
        let renderedText = AttributedString(BBRenderer().render(text: text))
        let builder = BBBuilder(attachments: attachments)
        let nodes = BBAttributedParser.parse(text: renderedText)
        return builder.mergeTextNodes(nodes)
    }
    
    // MARK: - Properties
    
    private var attachments: [Post.Attachment]
    
    // MARK: - Init
    
    private init(attachments: [Post.Attachment]) {
        self.attachments = attachments
    }
    
    // MARK: - Implementation
    
    private func mergeTextNodes(_ nodes: [BBContainerNode], listType: BBContainerNode.ListType? = nil) -> [BBContainerNode] {
        var mergedNodes: [BBContainerNode] = []
        
        for (index, node) in nodes.enumerated() {
            // print("NEW NODE: \(node)")
            switch node {
            case .text(let text), .snapback(let text), .mergetime(let text), .img(let text), .attachment(let text), .smile(let text):
                // ЕСЛИ у нас есть нода ДО текущей и это НЕ пустой текст
                if let last = mergedNodes.last, case let .text(lastText) = last, !last.isEmptyText {
                    let mutableText = NSMutableAttributedString(attributedString: lastText)
                    
                    // ЕСЛИ мы в листе ИЛИ последний (такое может быть?) текст был "[*]", то мержим с последним текстом
                    if listType != nil || lastText.string.count == 3 && lastText.string.prefix(3) == "[*]" {
                        mergedNodes[mergedNodes.count - 1] = unwrap(node: node, with: mutableText)
                    } else if case .img = node {
                        // ЕСЛИ нода картинки, ТО мержим как атач
                        mergedNodes[mergedNodes.count - 1] = unwrap(node: node, with: mutableText)
                    } else if case .attachment = node {
                        // ЕСЛИ нода атача, ТО мержим как атач
                        mergedNodes[mergedNodes.count - 1] = unwrap(node: node, with: mutableText)
                    } else if !mutableText.string.isEmpty {
                        if index < nodes.count - 1, nodes[index + 1].isTextable {
                            // ЕСЛИ нода НЕ последняя и следующая нода текстовая, ТО мержим с предыдущим текстом
                            var isAttachmentDelimeter = false
                            if case .attachment = nodes[index - 1] { isAttachmentDelimeter = true }
                            mergedNodes[mergedNodes.count - 1] = unwrap(node: node, with: mutableText, isAttachmentDelimeter: isAttachmentDelimeter)
                        } else {
                            // ЕСЛИ нода последняя ИЛИ если следующая нода НЕ текстовая, ТО тримим с конца
                            mergedNodes[mergedNodes.count - 1] = unwrap(node: node, with: mutableText, trimTrailing: true)
                        }
                    } else {
                        fatalError("?")
                    }
                } else { // ЕСЛИ ноды ДО нет или она НЕ текстовая или пустая
                    if index < nodes.count - 1, nodes[index + 1].isTextable, !nodes[index + 1].isMedia, !nodes[index + 1].isEmptyText {
                        // ЕСЛИ следующая нода текстовая И НЕ медиа И НЕ пустая, ТО тримим только leading
                        let textNode = unwrap(node: node, with: text, isFirst: true, trimLeading: true)
                        if !textNode.isEmptyText { mergedNodes.append(textNode) }
                    } else {
                        // ЕСЛИ следующая нода НЕ текстовая И/ИЛИ медиа И/ИЛИ пустая
                        switch node {
                        case .img, .attachment:
                            // И текущая нода это картинка/атач, ТО мержим как самостоятельные ноды
                            if index < nodes.count - 1, nodes[index + 1].startsWithSpace {
                                let textNode = unwrap(node: node, with: text, isFirst: true)//, trimLeading: true, trimTrailing: true)
                                if !textNode.isEmptyText { mergedNodes.append(textNode) }
                            } else {
                                mergedNodes.append(node)
                            }
                        default:
                            // ТО тримим с обоих краев
                            let trimTrailing = !(nodes[safe: index + 1]?.isTextable ?? false)
                            let textNode = unwrap(node: node, with: text, isFirst: true, trimLeading: true, trimTrailing: trimTrailing)
                            if !textNode.isEmptyText { mergedNodes.append(textNode) }
                        }
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
                mergedNodes.append(.list(type, mergeTextNodes(array, listType: type)))
                
            case .code(let title, let array):
                mergedNodes.append(.code(title, mergeTextNodes(array)))
                
            case .hide(let array):
                mergedNodes.append(.hide(mergeTextNodes(array)))
                
            case .cur(let array):
                mergedNodes.append(.cur(mergeTextNodes(array)))
                
            case .mod(let array):
                mergedNodes.append(.mod(mergeTextNodes(array)))
                
            case .ex(let array):
                mergedNodes.append(.ex(mergeTextNodes(array)))
            }
        }
        
        // TODO: Тримить сразу в коде выше?
        var trimmedNodes: [BBContainerNode] = []
        for node in mergedNodes {
            if case let .text(text) = node {
                let text = text.trimmingNewlines()
                if !text.string.isEmpty {
                    trimmedNodes.append(.text(text))
                }
            } else {
                trimmedNodes.append(node)
            }
        }
        
        return trimmedNodes
    }
    
    /// Превращает text / snapback / mergetime / img / attachment / smile в текстовую ноду
    private func unwrap(
        node: BBContainerNode,
        with combinedText: NSAttributedString,
        isFirst: Bool = false,
        isAttachmentDelimeter: Bool = false,
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
        trimLeading: Bool = false,
        trimTrailing: Bool = false
    ) -> BBContainerNode {
        // TODO: Вынести isFirst обработчики
        switch node {
        case .text(let text):
            let mutableString = NSMutableAttributedString(
                attributedString: text.trimmingNewlines(leading: trimLeading, trailing: trimTrailing)
            )
            if isAttachmentDelimeter {
                if mutableString.string.prefix(1) == " " {
                    mutableString.replaceCharacters(in: NSRange(location: 0, length: 1), with: "\n")
                }
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
