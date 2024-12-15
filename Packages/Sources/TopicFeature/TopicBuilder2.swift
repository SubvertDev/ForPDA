//
//  TopicBuilder.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 18.11.2024.
//

import SwiftUI
import SharedUI
import ComposableArchitecture
import ParsingClient

public struct QuoteMetadata: Hashable, Equatable {
    public var name: String
    public var date: String
    public var postId: Int?
    
    var plain: String {
        if let postId {
            return "name=\"\(name)\" date=\"\(date)\" post=\(postId)"
        } else {
            return "name=\"\(name)\" date=\"\(date)\""
        }
    }
}

public enum QuoteType2: Hashable, Equatable {
    case title(String)
    case metadata(QuoteMetadata)
}

public enum NoticeType: String, Hashable, Equatable {
    case curator = "cur"
    case moderator = "mod"
    case admin = "ex"
    
    var title: String {
        switch self {
        case .curator:   return "Куратор"
        case .moderator: return "Модератор"
        case .admin:     return "Администратор"
        }
    }
    
    var color: Color {
        switch self {
        case .curator:   return Color.Main.green
        case .moderator: return Color.Theme.primary
        case .admin:     return Color.Main.red
        }
    }
}

public struct Metadata: Hashable, Equatable {
    let range: Range<String.Index>
    var attributes: AttributeContainer?
    var attributed: AttributedString?
    
    init(
        range: Range<String.Index>,
        attributes: AttributeContainer? = nil,
        attributed: AttributedString? = nil
    ) {
        self.range = range
        self.attributes = attributes
        self.attributed = attributed
    }
}

//public enum CodeType: Hashable {
//    case none
//    case title(String)
//}

public struct UserQuote2: Hashable {
    public let name: String
    public let date: String
    public let postId: Int
}

public indirect enum TopicType2: Hashable, Equatable {
    case text(String, Metadata)
    case attachment(Int)
    case image(URL)
    case left([TopicType2])
    case center([TopicType2])
    case right([TopicType2])
    case spoiler([TopicType2], String?, AttributedString?)
    case quote([TopicType2], QuoteType2?)
    case code(TopicType2, CodeType)
    case list([TopicType2])
    case notice([TopicType2], NoticeType)
    case bullet([TopicType2])
}

public indirect enum TopicTypeUI: Hashable, Equatable {
    case text(AttributedString)
    case attachment(Int)
    case image(URL)
    case left([TopicTypeUI])
    case center([TopicTypeUI])
    case right([TopicTypeUI])
    case spoiler([TopicTypeUI], AttributedString?)
    case quote([TopicTypeUI], QuoteType2?)
    case code(TopicTypeUI, CodeType)
    case list([TopicTypeUI])
    case notice([TopicTypeUI], NoticeType)
    case bullet([TopicTypeUI])
}

public class TopicBuilder2 {
    
    var spoilerCount = 0
    
    func build2(from content: NSAttributedString) throws -> [TopicTypeUI] {
        let attributedString = AttributedString(content)
        let scanner = Scanner(string: String(attributedString.characters[...]))
        scanner.caseSensitive = true
        let types = parse(with: scanner)
        
        var attributedRanges: [(Range<AttributedString.Index>, AttributeContainer)] = []
        for run in attributedString.runs {
            let attributes = (run.range, run.attributes)
            //print("[RUN] \(attributes)")
            attributedRanges.append(attributes)
        }

        let attributedTypes = applyAttributes(attributedRanges, of: attributedString, to: types)
        return attributedTypes.map { twoToUI($0) }
    }
    
    private func applyAttributes(_ attributedRun: [(Range<AttributedString.Index>, AttributeContainer)], of attributedString: AttributedString, to string: String) -> AttributedString? {
        guard let attributedTextRange = attributedString.range(of: string) else { fatalError("no string match found") }
        for (attributedRunRange, attributeContainer) in attributedRun {
            if attributedTextRange.overlaps(attributedRunRange) {
                var newAttributedString = AttributedString(string)
                // TODO: Move to defaults somewhere else
                newAttributedString.foregroundColor = UIColor(Color.Labels.primary)
                newAttributedString.font = UIFont.preferredFont(forTextStyle: .callout)
                let originalTextInRange = attributedString[attributedRunRange]
                if let newTextRange = newAttributedString.range(of: String(originalTextInRange.characters)) {
                    newAttributedString[newTextRange].mergeAttributes(attributeContainer)
                    return newAttributedString
                }
                return newAttributedString
            }
        }
        return nil
    }
    
    private func applyAttributes(_ attributedRun: [(Range<AttributedString.Index>, AttributeContainer)], of attributedString: AttributedString, to types: [TopicType2]) -> [TopicType2] {
        var types = types
        for index in types.indices {
            switch types[index] {
            case let .text(string, metadata):
                // Trying to find same range of text in original string
                guard let attributedTextRange = attributedString.range(of: string) else {
                    print("[ATTRIBUTES] No range found for string")
                    continue
                }
                
                // When found, iterating over attributed runs to find overlaps
                for (attributedRunRange, attributeContainer) in attributedRun {
                    if attributedTextRange.overlaps(attributedRunRange) {
                        // We store modified attributed string into metadata, so we need to extract it each time we
                        // run this to not overwrite any of the attributes (not very optimal, but works for now)
                        var newAttributedString = AttributedString(string)
                        // TODO: Move to defaults somewhere else
                        newAttributedString.font = UIFont.preferredFont(forTextStyle: .callout)
                        newAttributedString.foregroundColor = UIColor(Color.Labels.primary)
                        if case let .text(_, modifiedMetadata) = types[index] {
                            if let savedAttributedString = modifiedMetadata.attributed {
                                newAttributedString = savedAttributedString
                            }
                        }
                        
                        // If we have a text match, update our text with its metadata
                        let originalTextInRange = attributedString[attributedRunRange]
                        if let newTextRange = newAttributedString.range(of: String(originalTextInRange.characters)) {
                            newAttributedString[newTextRange].mergeAttributes(attributeContainer)
                        }
                        let newMetadata = Metadata(range: metadata.range, attributed: newAttributedString)
                        types[index] = .text(string, newMetadata)
                    } else {
                        // No overlap
                    }
                }
                
            case let .left(array):
                types[index] = .left(applyAttributes(attributedRun, of: attributedString, to: array))
                
            case let .center(array):
                types[index] = .center(applyAttributes(attributedRun, of: attributedString, to: array))
                
            case let .right(array):
                types[index] = .right(applyAttributes(attributedRun, of: attributedString, to: array))

            case let .spoiler(array, info, attrStr):
                var attrStr = attrStr
                if let info { attrStr = applyAttributes(attributedRun, of: attributedString, to: info) }
                types[index] = .spoiler(applyAttributes(attributedRun, of: attributedString, to: array), info, attrStr)
                
            case let .quote(array, info):
                types[index] = .quote(applyAttributes(attributedRun, of: attributedString, to: array), info)
                
            case let .list(array):
                types[index] = .list(applyAttributes(attributedRun, of: attributedString, to: array))
                
            case let .code(text, info):
                let text = applyAttributes(attributedRun, of: attributedString, to: [text])
                types[index] = .code(text.first!, info)
                
            case let .notice(array, info):
                types[index] = .notice(applyAttributes(attributedRun, of: attributedString, to: array), info)
                
            case let .bullet(array):
                types[index] = .bullet(applyAttributes(attributedRun, of: attributedString, to: array))

            case .attachment:
                break
            }
        }
        return types
    }
    
    func twoToUI(_ type: TopicType2) -> TopicTypeUI {
        switch type {
        case .text(let string, let metadata):
            if let attributed = metadata.attributed {
                //print("[CONVERTER] Returning meta-attributed: \(attributed)")
                return .text(attributed)
            } else {
                let attrStr = AttributedString(string)
                //print("[CONVERTER] Returning plain-attributed: \(attrStr)")
                return .text(attrStr)
            }
            
        case .attachment(let id):
            return .attachment(id)
            
        case .left(let array):
            var results: [TopicTypeUI] = []
            for item in array {
                results.append(twoToUI(item))
            }
            return .left(results)
            
        case .center(let array):
            var results: [TopicTypeUI] = []
            for item in array {
                results.append(twoToUI(item))
            }
            return .center(results)
            
        case .right(let array):
            var results: [TopicTypeUI] = []
            for item in array {
                results.append(twoToUI(item))
            }
            return .right(results)
            
        case .spoiler(let array, _, let attrStr):
            var results: [TopicTypeUI] = []
            for item in array {
                results.append(twoToUI(item))
            }
            return .spoiler(results, attrStr)
            
        case .quote(let array, let quoteType2):
            var results: [TopicTypeUI] = []
            for item in array {
                results.append(twoToUI(item))
            }
            return .quote(results, quoteType2)
            
        case .code(let text, let codeType):
            return .code(twoToUI(text), codeType)
            
        case .notice(let types, let noticeType):
            return .notice(types.map { twoToUI($0) }, noticeType)
            
        case .list(let array):
            var results: [TopicTypeUI] = []
            for item in array {
                results.append(twoToUI(item))
            }
            return .list(results)
            
        case .bullet(let types):
            return .bullet(types.map { twoToUI($0) })
        }
    }
    
    let closingTags = ["[/spoiler]", "[/quote]", "[/list]", "[/left]", "[/center]", "[/right]", "[/code]", "[/cur]", "[/mod]", "[/ex]"]
    let tagsWithInfo = ["[quote ", "[quote=", "[spoiler=", "[attachment=", "[code="]
    
    enum CurrentTag {
        case spoiler
        case quote
        case list
        case left
        case center
        case right
        case code
        case notice
        case none
    }
    var currentTag: CurrentTag = .none {
        didSet { calculate()}
    }
    
    var listCount = 0 {
        didSet { calculate() }
    }
    var inList = false
    
    private func calculate() {
        inList = listCount > 0
        print("[COUNTER] List: \(listCount)")
    }
    
    private func printRemaining(_ scanner: Scanner, isEnabled: Bool = true) -> String {
        return isEnabled
            ? remainingString(scanner)
                .prefix(100)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: "")
            : ""
    }
    
    enum ClosestListTagIndex {
        case newline(Int)
        case bullet(Int)
        case none
    }
    
    private func closestListTagsIndexes(_ scanner: Scanner) -> ClosestListTagIndex {
        let newlineIndex = remainingString(scanner).firstIndex(of: "\n")
        let bulletIndex = remainingString(scanner).firstRange(of: "[*]")?.lowerBound
        let remainingString = remainingString(scanner)
        if let newlineIndex, let bulletIndex {
            if newlineIndex < bulletIndex {
                return .newline(newlineIndex.utf16Offset(in: remainingString))
            } else {
                return .bullet(bulletIndex.utf16Offset(in: remainingString))
            }
        } else if let newlineIndex {
            return .newline(newlineIndex.utf16Offset(in: remainingString))
        } else if let bulletIndex {
            return .bullet(bulletIndex.utf16Offset(in: remainingString))
        } else {
            return .none
        }
    }
    
    func parse(with scanner: Scanner) -> [TopicType2] {
        // print("[SCANNER] New instance called")
        var results: [TopicType2] = []
        
        while !scanner.isAtEnd {
            print("[SCANNER] New iteration >>> \"\(printRemaining(scanner))\"")
            
            guard let (tag, attributes, nextTagIndex) = firstFoundTagAndIndex(in: remainingString(scanner)) else {
                print("[SCANNER] No more tags >>> \"\(printRemaining(scanner))\"")
                if !remainingString(scanner).isEmpty {
                    print("[SCANNER] Got remaining text: \(printRemaining(scanner))")
                    let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                    let text = remainingString(scanner).trimmingCharacters(in: .whitespacesAndNewlines)
                    results.append(.text(text, metadata))
                }
                print("[SCANNER] Finished with \(results.count) results")
                return results
            }
            
            var nextTag = tag
            
            scanner.charactersToBeSkipped = inList ? nil : .whitespacesAndNewlines
            
            // List parsing aka bullets and nested stuff
            if inList, currentTag == .list {
                print("[SCANNER] In list check (\(currentTag))")
                let indexes = closestListTagsIndexes(scanner)
                //print(indexes)
                //print(printRemaining(scanner))
                // TODO: Merge into one case?
                switch indexes {
                case .newline(let newline):
                    if newline < nextTagIndex, currentTag == .list {
                        print("[SCANNER] Newline \(newline) < nextTagIndex \(nextTagIndex)")
                        // If we have newline before next tag, just parsing it
                        if let string = scanner.scanUpToString("\n") {
                            print("[SCANNER] List newline parsed string: \(string)")
                            let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                            results.append(.bullet([.text(string, metadata)])) // TODO: Not sure if putting text is enough
                            _ = scanner.scanString("\n")
                            continue
                        } else {
                            _ = scanner.scanString("\n")
                            continue
                        }
                    } else if nextTag == "[/list]", let string = scanner.scanUpToString("[/list]") {
                        print("[SCANNER] List newline list ending parsed string: \(string)")
                        let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                        results.append(.bullet([.text(string, metadata)])) // TODO: Not sure if putting text is enough
                    } else {
                        print("[SCANNER] Newline edge case")
                    }
                    
                case .bullet(let bullet):
                    if bullet < nextTagIndex, currentTag == .list {
                        print("[SCANNER] Bullet \(bullet) < nextTagIndex \(nextTagIndex)")
                        if let string = scanner.scanUpToString("[*]") {
                            print("[SCANNER] List bullet parsed string: \(string)")
                            if string.isEmpty {
                                _ = scanner.scanString("[*]")
                                continue
                            }
                            let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                            results.append(.bullet([.text(string, metadata)])) // TODO: Not sure if putting text is enough
                            _ = scanner.scanString("[*]")
                            continue
                        } else {
                            _ = scanner.scanString("[*]")
                            continue
                        }
                    } else {
                        print("[SCANNER] STOP CASE BULLET")
                    }
                    
                case .none:
                    break
                }
            }
            
            scanner.charactersToBeSkipped = inList ? nil : .whitespacesAndNewlines
            
            print("[SCANNER] Got tag \(nextTag) at \(nextTagIndex) >>> \"\(printRemaining(scanner))\"")
            
            // Don't consume closing tags so they can finish
            let hasEndingTags = closingTags.contains(nextTag)
            // Don't consume tags with metadata so it can be parsed later
            let hasTagsWithInfo = tagsWithInfo.contains(nextTag)
            
            if let text = scanner.scanUpToString(nextTag) {
                print("[SCANNER] Got text \"\(text.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: ""))\" before \(nextTag) >>> \"\(printRemaining(scanner))\"")
                let attributes = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                results.append(.text(text.trimmingCharacters(in: .whitespacesAndNewlines), attributes))

                if !hasEndingTags && !hasTagsWithInfo {
                    print("[SCANNER] Consuming \(nextTag)")
                    _ = scanner.scanString(nextTag)
                } else {
                    print("[SCANNER] Did not consume \(nextTag)")
                }
            } else {
                if !hasEndingTags && !hasTagsWithInfo {
                    print("[SCANNER] No text before \(nextTag), consume & continue")
                    _ = scanner.scanString(nextTag)
                } else {
                    print("[SCANNER] No text before \(nextTag), did not consume")
                }
            }
            
            if nextTag.contains("[quote ") || nextTag.contains("[quote=") {
                print("[SCANNER] Swizzled from \(nextTag) to [quote]")
                nextTag = "[quote]"
            }
            
            if nextTag.contains("[spoiler=") {
                print("[SCANNER] Swizzled from \(nextTag) to [spoiler]")
                nextTag = "[spoiler]"
            }
            
            if nextTag.contains("[attachment=") {
                print("[SCANNER] Swizzled from \(nextTag) to [attachment]")
                nextTag = "[attachment]"
            }
            
            if nextTag.contains("[code=") {
                print("[SCANNER] Swizzled from \(nextTag) to [code]")
                nextTag = "[code]"
            }
            
            print("[SCANNER] Starting to switch on \(nextTag)")
            
            switch nextTag {
            case "[left]":
                let left = parseLeft(from: scanner)
                if case .left = left { results.append(left) } else { fatalError("non left return") }
                
            case "[center]":
                let center = parseCenter(from: scanner)
                if case .center = center { results.append(center) } else { fatalError("non center return") }
                
            case "[right]":
                let right = parseRight(from: scanner)
                if case .right = right { results.append(right) } else { fatalError("non right return") }
                
            case "[attachment]":
                let attachment = parseAttachment(from: scanner, attributes: attributes!)
                if case .attachment = attachment { results.append(attachment) } else { fatalError("non attachment return") }
                
            case "[spoiler]":
                spoilerCount += 1
                let spoiler = parseSpoiler(from: scanner, attributes: attributes)
                if case .spoiler = spoiler { results.append(spoiler) } else { fatalError("non spoiler return") }
                
            case "[list]":
                let list = parseList(from: scanner)
                if case .list = list { results.append(list) } else { fatalError("non list return") }
                
            case "[quote]":
                let quote = parseQuote(from: scanner, attributes: attributes)
                if case .quote = quote { results.append(quote) } else { fatalError("non quote return") }
                
            case "[code]":
                let code = parseCode(from: scanner, attributes: attributes)
                if case .code = code { results.append(code) } else { fatalError("non code return") }
                
            case "[cur]", "[mod]", "[ex]":
                let notice = parseNotice(from: scanner, tag: nextTag)
                if case .notice = notice { results.append(notice) } else { fatalError("non notice return") }
                
            case "[/spoiler]":
                spoilerCount -= 1
                if spoilerCount < 0 {
                    print("wrong amount of spoilers, consume & skip")
                    _ = scanner.scanString(nextTag)
                    spoilerCount = 0
                } else {
                    print("[SCANNER] Closing tag \(nextTag), returning results")
                    return results
                }
                
            case "[/quote]", "[/code]", "[/list]", "[/left]", "[/center]", "[/right]", "[/cur]", "[/mod]", "[/ex]":
                print("[SCANNER] Closing tag \(nextTag), returning results")
                return results
                
            default:
                if nextTag.contains("/") {
                    print("[SCANNER] Possibly closing tag (\(nextTag)), do nothing >>> \(printRemaining(scanner))")
                } else {
                    fatalError("3")
                }
            }
        }
        
        print("[SCANNER] Finished with \(results.count) results")
        return results
    }
    
    // MARK: - Notice
    
    func parseNotice(from scanner: Scanner, tag: String) -> TopicType2 {
        currentTag = .notice
        
        var closingTag = tag
        closingTag.insert("/", at: closingTag.index(closingTag.startIndex, offsetBy: 1))
        var results: [TopicType2] = []
        
        while !scanner.isAtEnd {
            if scanner.scanString(closingTag) != nil {
                print("[NOTICE] Found end of \(closingTag)")
                break
            } else {
                print("[NOTICE] Found no end tag >>> \(printRemaining(scanner))")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return .notice(results, NoticeType(rawValue: String(tag.dropFirst().dropLast()))!)
    }
    
    // MARK: - Left
    
    func parseLeft(from scanner: Scanner) -> TopicType2 {
        defer { if inList { currentTag = .list } }
        currentTag = .left
        
        var results: [TopicType2] = []
        
        while !scanner.isAtEnd {
            print("[LEFT] New iteration: \(printRemaining(scanner))")
            if scanner.scanString("[left]") != nil {
                // TODO: Can it actually find it since it's consumed in parse(with:)?
                print("[LEFT] Found left")
                let types = parse(with: scanner)
                results.append(.center(types))
            } else if scanner.scanString("[/left]") != nil {
                print("[LEFT] Found end of left")
                break
            } else {
                print("[LEFT] Found no left tag >>> \(printRemaining(scanner))")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return .left(results)
    }
    
    // MARK: - Center
        
    func parseCenter(from scanner: Scanner) -> TopicType2 {
        defer { if inList { currentTag = .list } }
        currentTag = .center
        
        var results: [TopicType2] = []
        
        while !scanner.isAtEnd {
            print("[CENTER] New iteration: \(printRemaining(scanner))")
            if scanner.scanString("[center]") != nil {
                // TODO: Can it actually find it since it's consumed in parse(with:)?
                print("[CENTER] Found center")
                let types = parse(with: scanner)
                results.append(.center(types))
            } else if scanner.scanString("[/center]") != nil {
                print("[CENTER] Found end of center")
                break
            } else {
                print("[CENTER] Found no center tag >>> \(printRemaining(scanner))")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return .center(results)
    }
    
    // MARK: - Right
    
    func parseRight(from scanner: Scanner) -> TopicType2 {
        defer { if inList { currentTag = .list } }
        currentTag = .right
        
        var results: [TopicType2] = []
        
        while !scanner.isAtEnd {
            print("[RIGHT] New iteration: \(printRemaining(scanner))")
            if scanner.scanString("[right]") != nil {
                // TODO: Can it actually find it since it's consumed in parse(with:)?
                print("[RIGHT] Found right")
                let types = parse(with: scanner)
                results.append(.center(types))
            } else if scanner.scanString("[/right]") != nil {
                print("[RIGHT] Found end of right")
                break
            } else {
                print("[RIGHT] Found no right tag >>> \(printRemaining(scanner))")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return .right(results)
    }
    
    // MARK: - Code
    
    func parseCodeAttributes(_ string: String?) -> CodeType {
        guard let string else { return .none }
        
        if string.first == "=" {
            let title = String(string.dropFirst().dropLast()) // Removing " "
            return .title(title)
        } else {
            fatalError("[CODE PARSER] Unrecognized pattern")
        }
    }
    
    func parseCode(from scanner: Scanner, attributes: String?) -> TopicType2 {
        currentTag = .code
        
        var results: [TopicType2] = []
        let attributes = parseCodeAttributes(attributes)
        
        while !scanner.isAtEnd {
            if let string = scanner.scanUpToString("[/code]") {
                let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
                let type: TopicType2 = .text(text, metadata)
                results.append(type)
            } else if scanner.scanString("[/code]") != nil {
                print("[QUOTE] Found end of code (\(attributes != .none ? "had" : "no") attributes)")
                break
            } else {
                print("[QUOTE] Found no code tag >>> \(printRemaining(scanner))")
                fatalError("[QUOTE] Unrecognized pattern")
            }
        }
        
        return .code(results.first!, attributes)
    }
    
    // MARK: - Quote

    func parseQuoteAttributes(_ string: String?) -> QuoteType2? {
        guard let string else {
            print("[QUOTE PARSER] No attributes found")
            return nil
        }
        
        if string.first == "=" {
            let title = string.components(separatedBy: "\"")[1]
            print("[QUOTE PARSER] Found title attributes: \"\(title)\"")
            return .title(title)
        } else if string.first == " " {
            let pattern = /name=\"([^\"]+)\" date=\"([^\"]+)\"(?: post=(\d+))?/
            if let match = string.firstMatch(of: pattern) {
                let metadata = QuoteMetadata(
                    name: String(match.output.1),
                    date: String(match.output.2),
                    postId: Int(String(match.output.3 ?? ""))
                )
                print("[QUOTE PARSER] Found metadata attributes: \"\(metadata)\"")
                return .metadata(metadata)
            } else {
                fatalError("[QUOTE PARSER] Unrecognized pattern")
            }
        } else {
            return nil
        }
    }

    func parseQuote(from scanner: Scanner, attributes: String? = nil) -> TopicType2 {
        currentTag = .quote
        
        var results: [TopicType2] = []
        let attributes = parseQuoteAttributes(attributes)
        
        while !scanner.isAtEnd {
            print("[QUOTE] New iteration: \(printRemaining(scanner))")
            
            if let attributes {
                var title = "title"
                if case let .title(text) = attributes { title = text }
                var metadata = QuoteMetadata(name: "", date: "", postId: nil)
                if case let .metadata(quoteMetadata) = attributes {
                    metadata.name = quoteMetadata.name
                    metadata.date = quoteMetadata.date
                    metadata.postId = quoteMetadata.postId
                }
                
                // TODO: Instead of making scanString correct, maybe just retract some of text after parse?
                
                if scanner.scanString("[quote " + metadata.plain + "]") != nil {
                    // TODO: Is this even working?
                    print("[QUOTE] Found quote (metadata mode)")
                    let types = parse(with: scanner)
                    results.append(.quote(types, attributes))
                } else if scanner.scanString("[quote=\"" + title + "\"]") != nil {
                    // TODO: Is this even working?
                    print("[QUOTE] Found quote (title mode)")
                    let types = parse(with: scanner)
                    results.append(.quote(types, attributes))
                } else if scanner.scanString("[/quote]") != nil {
                    print("[QUOTE] Found end of quote (had attributes)")
                    break
                } else {
                    print("[QUOTE] Found no quote tag >>> \(printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                }
            } else {
                if scanner.scanString("[quote]") != nil {
                    // TODO: Can it actually find it since it's consumed in parse(with:)?
                    print("[QUOTE] Found quote (plain mode)")
                    let types = parse(with: scanner)
                    results.append(.quote(types, attributes))
                } else if scanner.scanString("[/quote]") != nil {
                    print("[QUOTE] Found end of quote (had no attributes)")
                    break
                } else {
                    print("[QUOTE] Found no quote tag >>> \(printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                }
            }
        }
        
        print("[QUOTE] Finished with \(results.count) results")
        return .quote(results, attributes)
    }
    
    // MARK: - Attachment
    
    func parseAttachmentAttributes(_ string: String) -> Int {
        let pattern = /=\"(\d+):/
        if let match = string.firstMatch(of: pattern) {
            return Int(match.output.1) ?? 0
        } else {
            return 0
        }
    }
    
    func parseAttachment(from scanner: Scanner, attributes: String) -> TopicType2 {
        let attachmentId = parseAttachmentAttributes(attributes)
        return .attachment(attachmentId)
    }

    // MARK: - Spoiler

    func parseSpoilerAttributes(_ string: String?) -> String? {
        guard let string else {
            print("[SPOILER PARSER] Found no attributes")
            return nil
        }
        
        let pattern = /=(?:"([^"]+)"|([^\]]+))/
        if let match = string.firstMatch(of: pattern) {
            if let output1 = match.output.1 {
                print("[SPOILER PARSER] Found title: \(output1)")
                return String(output1)
            } else if let output2 = match.output.2 {
                print("[SPOILER PARSER] Found title: \(output2)")
                return String(output2)
            } else {
                fatalError("[SPOILER PARSER] Unrecognized pattern")
            }
        } else {
            print("[SPOILER PARSER] Found no attributes")
            return nil
        }
    }

    func parseSpoiler(from scanner: Scanner, attributes: String? = nil) -> TopicType2 {
        currentTag = .spoiler
        
        var results: [TopicType2] = []
        let attributes = parseSpoilerAttributes(attributes)
        
        while !scanner.isAtEnd {
            if let attributes {
                if scanner.scanString("[spoiler=\"\(attributes)\"]") != nil {
                    print("[SPOILER] Found spoiler tag (title mode, with quotes) >>> \(printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                } else if scanner.scanString("[spoiler=\(attributes)]") != nil {
                    print("[SPOILER] Found spoiler tag (title mode, no quotes) >>> \(printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                } else if scanner.scanString("[/spoiler]") != nil {
                    print("[SPOILER] Found end of spoiler (had attributes)")
                    break
                } else {
                    print("[SPOILER] No more spoiler tag >>> \(printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                }
            } else {
                if scanner.scanString("[spoiler]") != nil {
                    print("[SPOILER] Found spoiler tag (plain mode)")
                    let types = parse(with: scanner)
                    results.append(.spoiler(types, nil, nil))
                } else if scanner.scanString("[/spoiler]") != nil {
                    print("[SPOILER] Found end of spoiler (had no attributes)")
                    break
                } else {
                    print("[SPOILER] No more spoiler tag >>> \(printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                }
            }
        }
        
        print("[SPOILER] Finished with \(results.count)")
        return .spoiler(results, attributes, nil)
    }

    // MARK: - List
    
    func parseList(from scanner: Scanner) -> TopicType2 {
        defer { listCount -= 1 }
        currentTag = .list
        listCount += 1
        
        var results: [TopicType2] = []
        
        while !scanner.isAtEnd {
            if scanner.scanString("[*]") != nil {
                print("[LIST] Found [*] tag")
                let types = parse(with: scanner)
                results.append(.list(types))
            } else if scanner.scanString("[list]") != nil {
                print("[LIST] Found nested list")
                let list = parseList(from: scanner)
                results.append(list)
            } else if scanner.scanString("[/list]") != nil {
                break
            } else if scanner.scanString("\n") != nil {
                // TODO: Nested list case. Remove \n's in parsing instead?
                continue
            } else {
                // Non-list tags?
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        print("[LIST] Finished with \(results.count) results")
        return .list(results)
    }
    
    // MARK: - Helpers

    private func remainingString(_ scanner: Scanner) -> String {
        let currentIndex = scanner.currentIndex
        return String(scanner.string[currentIndex...])
    }
    
    func getRange(for text: String, from scanner: Scanner) -> Range<String.Index> {
        let string = scanner.string

        // Get the scanner's current index
        let currentIndex = scanner.currentIndex

        // Calculate start and end indices
        let startIndex = string.index(currentIndex, offsetBy: -text.count, limitedBy: string.startIndex) ?? string.startIndex
        let endIndex = string.index(startIndex, offsetBy: text.count, limitedBy: string.endIndex) ?? string.endIndex

        // Ensure the range is valid
        guard startIndex >= string.startIndex, endIndex <= string.endIndex else {
            fatalError("how???")
        }

        return startIndex..<endIndex
    }

    private func firstFoundTagAndIndex(in string: String) -> (tag: String, attributes: String?, index: Int)? {
        // Define valid tags
        let validTags: Set<String> = [
            "quote",
            "/quote",
            "spoiler",
            "/spoiler",
            "list",
            "/list",
            "code",
            "/code",
            "left",
            "/left",
            "center",
            "/center",
            "right",
            "/right",
            "cur",
            "/cur",
            "mod",
            "/mod",
            "ex",
            "/ex",
            "attachment"
        ]

        // Define tags directly in the regex pattern
        let pattern = /\[([a-zA-Z\/]+)([^\]]*)\]/
        
        for match in string.matches(of: pattern) {
            let tag = String(match.output.1)

            guard validTags.contains(tag) else {
                print("[VALIDATOR] Non-valid tag: \(tag)")
                continue
            }
            
            print("[VALIDATOR] String: \"\(string.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: ""))\" -> Tag: \(tag)")
            
            // Extract attributes string, if present
            let attributes = String(match.output.2)
            
            // Find the starting index of the match
            let index = string.distance(from: string.startIndex, to: match.range.lowerBound)
            
            if !attributes.isEmpty {
                print("[VALIDATOR] Returning with attributes")
                return (tag: "[\(tag)\(attributes)]", attributes: attributes, index: index)
            } else {
                return (tag: "[\(tag)]", attributes: nil, index: index)
            }
        }
        
        print("[VALIDATOR] Found no more matches")
        return nil
    }
}
