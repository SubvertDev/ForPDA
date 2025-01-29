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
import Models
import OSLog

// MARK: - !WARNING! -
// This is WIP draft until this comment is here

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

public struct UserQuote: Hashable {
    public let name: String
    public let date: String
    public let postId: Int
}

public indirect enum TopicType: Hashable, Equatable {
    case text(String, Metadata)
    case offtop(String, AttributedString?)
    case attachment(Int)
    case image(URL)
    case left([TopicType])
    case center([TopicType])
    case right([TopicType])
    case spoiler([TopicType], String?, AttributedString?)
    case quote([TopicType], QuoteType?)
    case code(TopicType, CodeType)
    case hide([TopicType], Int?)
    case list([TopicType], ListType)
    case notice([TopicType], NoticeType)
    case bullet([TopicType])
}

extension StringProtocol {

    func ranges<T: StringProtocol>(
        of stringToFind: T,
        options: String.CompareOptions = [],
        locale: Locale? = nil
    ) -> [Range<AttributedString.Index>] {

        var ranges: [Range<String.Index>] = []
        var attributedRanges: [Range<AttributedString.Index>] = []
        let attributedString = AttributedString(self)

        while let result = range(
            of: stringToFind,
            options: options,
            range: (ranges.last?.upperBound ?? startIndex)..<endIndex,
            locale: locale
        ) {
            ranges.append(result)
            let start = AttributedString.Index(result.lowerBound, within: attributedString)!
            let end = AttributedString.Index(result.upperBound, within: attributedString)!
            attributedRanges.append(start..<end)
        }
        return attributedRanges
    }
}

public class TopicBuilder {
    
    let isLoggerEnabled = false
    lazy var logger = isLoggerEnabled ? Logger() : Logger(.disabled)
    
    public init() {}
    
    public func build(from content: NSAttributedString) throws -> [TopicTypeUI] {
        let attributedString = AttributedString(content)
        let scanner = Scanner(string: String(attributedString.characters[...]))
        scanner.caseSensitive = true
        Logger().error("Preparse: \(Date.now)")
        let types = parse(with: scanner)
        Logger().error("PostParse: \(Date.now)")
        var attributedRanges: [(Range<AttributedString.Index>, AttributeContainer)] = []
        for run in attributedString.runs {
            let attributes = (run.range, run.attributes)
            //logger.log("[RUN] \(attributes)")
            attributedRanges.append(attributes)
        }

        Logger().error("Preapply: \(Date.now)")
        let attributedTypes = applyAttributes(attributedRanges, of: attributedString, to: types)
        Logger().error("Postapply: \(Date.now)")
        let uiTypes = attributedTypes.map { twoToUI($0) }
        return uiTypes
    }
    
    private func applyAttributes(_ attributedRun: [(Range<AttributedString.Index>, AttributeContainer)], of attributedString: AttributedString, to string: String) -> AttributedString? {
        guard let attributedTextRange = attributedString.range(of: string) else { fatalError("no string match found") }
        for (attributedRunRange, attributeContainer) in attributedRun {
            if attributedTextRange.overlaps(attributedRunRange) {
                var newAttributedString = AttributedString(string)
                // TODO: Move to defaults somewhere else
                newAttributedString.foregroundColor = UIColor(Color(.Labels.primary))
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
    
    private func applyAttributes(
        _ attributedRun: [(Range<AttributedString.Index>, AttributeContainer)],
        of attributedString: AttributedString,
        to types: [TopicType]
    ) -> [TopicType] {
        var types = types
        for index in types.indices {
            switch types[index] {
            case let .text(string, metadata):
                var newString = AttributedString(string)
                if case let .text(_, modifiedMetadata) = types[index] {
                    if let savedString = modifiedMetadata.attributed {
                        newString = savedString
                    }
                }
                let newAttributed = transferAttributes(from: attributedString, to: newString)
                let newMetadata = Metadata(range: metadata.range, attributed: newAttributed)
                types[index] = .text(string, newMetadata)
                
            case let .offtop(string, _):
                var newAttributedString = AttributedString(string)
                if case let .offtop(_, modifiedAttributedString) = types[index] {
                    if let modifiedAttributedString {
                        newAttributedString = modifiedAttributedString
                    } else {
                        var attributes = AttributeContainer()
                        attributes.foregroundColor = UIColor(Color(.Labels.quaternary))
                        attributes.font = UIFont.preferredFont(forTextStyle: .caption2)
                        newAttributedString.mergeAttributes(attributes)
                    }
                }
                types[index] = .offtop(string, newAttributedString)
                
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
                
            case let .list(array, listType):
                types[index] = .list(applyAttributes(attributedRun, of: attributedString, to: array), listType)
                
            case let .code(text, info):
                let text = applyAttributes(attributedRun, of: attributedString, to: [text])
                types[index] = .code(text.first!, info)
                
            case let .hide(array, info):
                types[index] = .hide(applyAttributes(attributedRun, of: attributedString, to: array), info)
                
            case let .notice(array, info):
                types[index] = .notice(applyAttributes(attributedRun, of: attributedString, to: array), info)
                
            case let .bullet(array):
                types[index] = .bullet(applyAttributes(attributedRun, of: attributedString, to: array))

            case .attachment, .image:
                break
            }
        }
        return types
    }
    
    private func transferAttributes(from source: AttributedString, to target: AttributedString) -> AttributedString {
        var result = target
        
        // Find the range of the target text in the source string
        guard let matchRange = source.range(of: String(target.characters[...])) else {
            // If target text is not found in the source, return the target as-is
            return result
        }
        
        // Iterate through all attribute runs in the source string
        for run in source.runs {
            let rangeInSource = run.range
            
            // Check if the run intersects with the matched range
            if rangeInSource.overlaps(matchRange) {
                // Calculate the overlapping range within the matched range
                let intersection = rangeInSource.clamped(to: matchRange)
                
                // Calculate the corresponding range in the target string
                let offsetStart = source.characters.distance(from: matchRange.lowerBound, to: intersection.lowerBound)
                let offsetEnd = source.characters.distance(from: intersection.lowerBound, to: intersection.upperBound)
                
                let startInTarget = result.characters.index(result.startIndex, offsetBy: offsetStart)
                let endInTarget = result.characters.index(startInTarget, offsetBy: offsetEnd)
                
                // Apply the attributes to the target string
                result[startInTarget..<endInTarget].setAttributes(run.attributes)
            }
        }
        
        return result
    }
    
    func twoToUI(_ type: TopicType) -> TopicTypeUI {
        switch type {
        case .text(let string, let metadata):
            if let attributed = metadata.attributed {
                //logger.log("[CONVERTER] Returning meta-attributed: \(attributed)")
                return .text(attributed)
            } else {
                let attrStr = AttributedString(string)
                //logger.log("[CONVERTER] Returning plain-attributed: \(attrStr)")
                return .text(attrStr)
            }
            
        case .offtop(let string, let attributedString):
            if let attributedString {
                return .text(attributedString)
            } else {
                return .text(AttributedString(string))
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
            
        case .hide(let array, let info):
            return .hide(array.map { twoToUI($0) }, info)
            
        case .notice(let types, let noticeType):
            return .notice(types.map { twoToUI($0) }, noticeType)
            
        case .image(let url):
            return .image(url)
            
        case .list(let array, let listType):
            var results: [TopicTypeUI] = []
            for item in array {
                results.append(twoToUI(item))
            }
            return .list(results, listType)
            
        case .bullet(let types):
            return .bullet(types.map { twoToUI($0) })
        }
    }
    
    let closingTags = ["[/spoiler]", "[/quote]", "[/list]", "[/left]", "[/center]", "[/right]", "[/code]", "[/hide]", "[/cur]", "[/mod]", "[/ex]", "[/img]", "[/offtop]"]
    let tagsWithInfo = ["[quote ", "[quote=", "[spoiler=", "[attachment=", "[code=", "[hide="]
    
    enum CurrentTag {
        case spoiler
        case quote
        case list
        case left
        case center
        case right
        case code
        case hide
        case offtop
        case notice
        case image
        case none
    }
    var currentTag: CurrentTag = .none {
        didSet { calculate()}
    }
    
    var spoilerCount = 0
    var listCount = 0 {
        didSet { calculate() }
    }
    var inList = false
    
    private func calculate() {
        inList = listCount > 0
        logger.log("[COUNTER] List: \(self.listCount)")
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
    
    func parse(with scanner: Scanner) -> [TopicType] {
        // logger.log("[SCANNER] New instance called")
        var results: [TopicType] = []
        
        while !scanner.isAtEnd {
            logger.log("[SCANNER] New iteration >>> \"\(self.printRemaining(scanner))\"")
            
            guard let (tag, attributes, nextTagIndex) = firstFoundTagAndIndex(in: remainingString(scanner)) else {
                logger.log("[SCANNER] No more tags >>> \"\(self.printRemaining(scanner))\"")
                if !remainingString(scanner).isEmpty {
                    logger.log("[SCANNER] Got remaining text: \(self.printRemaining(scanner))")
                    let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                    let text = remainingString(scanner).trimmingCharacters(in: .whitespacesAndNewlines)
                    results.append(.text(text, metadata))
                }
                logger.log("[SCANNER] Finished with \(results.count) results")
                return results
            }
            
            var nextTag = tag
            
            scanner.charactersToBeSkipped = inList ? nil : .whitespacesAndNewlines
            
            // List parsing aka bullets and nested stuff
            if inList, currentTag == .list {
                logger.log("[SCANNER] In list check")
                let indexes = closestListTagsIndexes(scanner)
                //print(indexes)
                //print(printRemaining(scanner))
                // TODO: Merge into one case?
                switch indexes {
                case .newline(let newline):
                    if newline < nextTagIndex, currentTag == .list {
                        logger.log("[SCANNER] Newline \(newline) < nextTagIndex \(nextTagIndex)")
                        // If we have newline before next tag, just parsing it
                        if let string = scanner.scanUpToString("\n") {
                            logger.log("[SCANNER] List newline parsed string: \(string)")
                            let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                            results.append(.bullet([.text(string, metadata)])) // TODO: Not sure if putting text is enough
                            _ = scanner.scanString("\n")
                            continue
                        } else {
                            _ = scanner.scanString("\n")
                            continue
                        }
                    } else if nextTag == "[/list]", let string = scanner.scanUpToString("[/list]") {
                        logger.log("[SCANNER] List newline list ending parsed string: \(string)")
                        let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                        results.append(.bullet([.text(string, metadata)])) // TODO: Not sure if putting text is enough
                    } else {
                        logger.log("[SCANNER] Newline edge case")
                    }
                    
                case .bullet(let bullet):
                    if bullet < nextTagIndex, currentTag == .list {
                        logger.log("[SCANNER] Bullet \(bullet) < nextTagIndex \(nextTagIndex)")
                        if let string = scanner.scanUpToString("[*]") {
                            logger.log("[SCANNER] List bullet parsed string: \(string)")
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
                        logger.log("[SCANNER] STOP CASE BULLET")
                    }
                    
                case .none:
                    break
                }
            }
            
            scanner.charactersToBeSkipped = inList ? nil : .whitespacesAndNewlines
            
            logger.log("[SCANNER] Got tag \(nextTag) at \(nextTagIndex) >>> \"\(self.printRemaining(scanner))\"")
            
            // Don't consume closing tags so they can finish
            let hasEndingTags = closingTags.contains(nextTag)
            // Don't consume tags with metadata so it can be parsed later
            let hasTagsWithInfo = tagsWithInfo.contains(nextTag)
            
            if let text = scanner.scanUpToString(nextTag) {
                logger.log("[SCANNER] Got text \"\(text.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: ""))\" before \(nextTag) >>> \"\(self.printRemaining(scanner))\"")
                if currentTag != .offtop {
                    let attributes = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                    results.append(.text(text.trimmingCharacters(in: .whitespacesAndNewlines), attributes))
                } else {
                    results.append(.offtop(text.trimmingCharacters(in: .whitespacesAndNewlines), nil))
                }

                if !hasEndingTags && !hasTagsWithInfo {
                    logger.log("[SCANNER] Consuming \(nextTag)")
                    _ = scanner.scanString(nextTag)
                } else {
                    logger.log("[SCANNER] Did not consume \(nextTag)")
                }
            } else {
                if !hasEndingTags && !hasTagsWithInfo {
                    logger.log("[SCANNER] No text before \(nextTag), consume & continue")
                    _ = scanner.scanString(nextTag)
                } else {
                    logger.log("[SCANNER] No text before \(nextTag), did not consume")
                }
            }
            
            if nextTag.contains("[quote ") || nextTag.contains("[quote=") {
                logger.log("[SCANNER] Swizzled from \(nextTag) to [quote]")
                nextTag = "[quote]"
            }
            
            if nextTag.contains("[spoiler=") {
                logger.log("[SCANNER] Swizzled from \(nextTag) to [spoiler]")
                nextTag = "[spoiler]"
            }
            
            if nextTag.contains("[attachment=") {
                logger.log("[SCANNER] Swizzled from \(nextTag) to [attachment]")
                nextTag = "[attachment]"
            }
            
            if nextTag.contains("[code=") {
                logger.log("[SCANNER] Swizzled from \(nextTag) to [code]")
                nextTag = "[code]"
            }
            
            if nextTag.contains("[hide=") {
                logger.log("[SCANNER] Swizzled from \(nextTag) to [hide]")
                nextTag = "[hide]"
            }
            
            logger.log("[SCANNER] Starting to switch on \(nextTag)")
            
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
                
            case "[list]", "[list=1]", "[list=I]", "[list=i]", "[list=A]":
                let list = parseList(from: scanner, listType: nextTag == "[list]" ? .bullet : .numeric)
                if case .list = list { results.append(list) } else { fatalError("non list return") }
                
            case "[quote]":
                let quote = parseQuote(from: scanner, attributes: attributes)
                if case .quote = quote { results.append(quote) } else { fatalError("non quote return") }
                
            case "[code]":
                let code = parseCode(from: scanner, attributes: attributes)
                if case .code = code { results.append(code) } else { fatalError("non code return") }
                
            case "[hide]":
                let hide = parseHide(from: scanner, attributes: attributes)
                if case .hide = hide { results.append(hide) } else { fatalError("non hide return") }
                
            case "[offtop]":
                let offtop = parseOfftop(from: scanner)
                results.append(contentsOf: offtop)
                
            case "[img]":
                let image = parseImage(from: scanner)
                if case .image = image { results.append(image) } else { fatalError("non image return") }
                
            case "[cur]", "[mod]", "[ex]":
                let notice = parseNotice(from: scanner, tag: nextTag)
                if case .notice = notice { results.append(notice) } else { fatalError("non notice return") }
                
            case "[/spoiler]":
                spoilerCount -= 1
                if spoilerCount < 0 {
                    logger.log("wrong amount of spoilers, consume & skip")
                    _ = scanner.scanString(nextTag)
                    spoilerCount = 0
                } else {
                    logger.log("[SCANNER] Closing tag \(nextTag), returning results")
                    return results
                }
                
            case "[/quote]", "[/code]", "[/hide]", "[/list]", "[/left]", "[/center]", "[/right]", "[/cur]", "[/mod]", "[/ex]", "[/img]", "[/offtop]":
                logger.log("[SCANNER] Closing tag \(nextTag), returning results")
                return results
                
            default:
                if nextTag.contains("/") {
                    logger.log("[SCANNER] Possibly closing tag (\(nextTag)), do nothing >>> \(self.printRemaining(scanner))")
                } else {
                    fatalError("3")
                }
            }
        }
        
        logger.log("[SCANNER] Finished with \(results.count) results")
        return results
    }
    
    // MARK: - Image
    
    func parseImage(from scanner: Scanner) -> TopicType {
        currentTag = .image
        var url: URL!
        
        while !scanner.isAtEnd {
            if let urlString = scanner.scanUpToString("[/img]") {
                url = URL(string: urlString)!
            } else if scanner.scanString("[/img]") != nil {
                break
            } else {
                fatalError("[IMAGE] Unrecognized pattern")
            }
        }
        
        return .image(url)
    }
    
    // MARK: - Notice
    
    func parseNotice(from scanner: Scanner, tag: String) -> TopicType {
        currentTag = .notice
        
        var closingTag = tag
        closingTag.insert("/", at: closingTag.index(closingTag.startIndex, offsetBy: 1))
        var results: [TopicType] = []
        
        while !scanner.isAtEnd {
            if scanner.scanString(closingTag) != nil {
                logger.log("[NOTICE] Found end of \(closingTag)")
                break
            } else {
                logger.log("[NOTICE] Found no end tag >>> \(self.printRemaining(scanner))")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return .notice(results, NoticeType(rawValue: String(tag.dropFirst().dropLast()))!)
    }
    
    // MARK: - Left
    
    func parseLeft(from scanner: Scanner) -> TopicType {
        defer { if inList { currentTag = .list } }
        currentTag = .left
        
        var results: [TopicType] = []
        
        while !scanner.isAtEnd {
            logger.log("[LEFT] New iteration: \(self.printRemaining(scanner))")
            if scanner.scanString("[left]") != nil {
                // TODO: Can it actually find it since it's consumed in parse(with:)?
                logger.log("[LEFT] Found left")
                let types = parse(with: scanner)
                results.append(.center(types))
            } else if scanner.scanString("[/left]") != nil {
                logger.log("[LEFT] Found end of left")
                break
            } else {
                logger.log("[LEFT] Found no left tag >>> \(self.printRemaining(scanner))")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return .left(results)
    }
    
    // MARK: - Center
        
    func parseCenter(from scanner: Scanner) -> TopicType {
        defer { if inList { currentTag = .list } }
        currentTag = .center
        
        var results: [TopicType] = []
        
        while !scanner.isAtEnd {
            logger.log("[CENTER] New iteration: \(self.printRemaining(scanner))")
            if scanner.scanString("[center]") != nil {
                // TODO: Can it actually find it since it's consumed in parse(with:)?
                logger.log("[CENTER] Found center")
                let types = parse(with: scanner)
                results.append(.center(types))
            } else if scanner.scanString("[/center]") != nil {
                logger.log("[CENTER] Found end of center")
                break
            } else {
                logger.log("[CENTER] Found no center tag >>> \(self.printRemaining(scanner))")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return .center(results)
    }
    
    // MARK: - Right
    
    func parseRight(from scanner: Scanner) -> TopicType {
        defer { if inList { currentTag = .list } }
        currentTag = .right
        
        var results: [TopicType] = []
        
        while !scanner.isAtEnd {
            logger.log("[RIGHT] New iteration: \(self.printRemaining(scanner))")
            if scanner.scanString("[right]") != nil {
                // TODO: Can it actually find it since it's consumed in parse(with:)?
                logger.log("[RIGHT] Found right")
                let types = parse(with: scanner)
                results.append(.center(types))
            } else if scanner.scanString("[/right]") != nil {
                logger.log("[RIGHT] Found end of right")
                break
            } else {
                logger.log("[RIGHT] Found no right tag >>> \(self.printRemaining(scanner))")
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
    
    func parseCode(from scanner: Scanner, attributes: String?) -> TopicType {
        currentTag = .code
        
        var results: [TopicType] = []
        let attributes = parseCodeAttributes(attributes)
        
        while !scanner.isAtEnd {
            if let string = scanner.scanUpToString("[/code]") {
                let metadata = Metadata(range: getRange(for: remainingString(scanner), from: scanner))
                let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
                let type: TopicType = .text(text, metadata)
                results.append(type)
            } else if scanner.scanString("[/code]") != nil {
                logger.log("[QUOTE] Found end of code (\(attributes != .none ? "had" : "no") attributes)")
                break
            } else {
                logger.log("[QUOTE] Found no code tag >>> \(self.printRemaining(scanner))")
                fatalError("[QUOTE] Unrecognized pattern")
            }
        }
        
        return .code(results.first!, attributes)
    }
    
    // MARK: - Hide
    
    func parseHideAttributes(_ string: String?) -> Int? {
        guard let string else {
            logger.log("[HIDE PARSER] No attributes found")
            return nil
        }
        
        if string.first == "=", let number = Int(String(string.dropFirst())) {
            return number
        } else {
            return nil
        }
    }
    
    func parseHide(from scanner: Scanner, attributes: String? = nil) -> TopicType {
        currentTag = .hide
        
        var results: [TopicType] = []
        let attributes = parseHideAttributes(attributes)
        
        while !scanner.isAtEnd {
            logger.log("[HIDE] New iteration")
            if scanner.scanString("[/hide]") != nil {
                logger.log("[HIDE] Found end of hide")
                break
            } else {
                logger.log("[HIDE] Found no hide tag, parsing insides")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return .hide(results, attributes)
    }
    
    // MARK: - Offtop
    
    func parseOfftop(from scanner: Scanner) -> [TopicType] {
        currentTag = .offtop
        
        var results: [TopicType] = []
        
        while !scanner.isAtEnd {
            logger.log("[OFFTOP] New iteration")
            if scanner.scanString("[/offtop]") != nil {
                logger.log("[OFFTOP] Found end of offtop")
                break
            } else {
                logger.log("[OFFTOP] Found no offtop tag, parsing insides")
                let types = parse(with: scanner)
                results.append(contentsOf: types)
            }
        }
        
        return results
    }
    
    // MARK: - Quote

    func parseQuoteAttributes(_ string: String?) -> QuoteType? {
        guard let string else {
            logger.log("[QUOTE PARSER] No attributes found")
            return nil
        }
        
        if string.first == "=" {
            let componentsQuote = string.components(separatedBy: "\"")
            if componentsQuote.count > 1 {
                let title = string.components(separatedBy: "\"")[1]
                logger.log("[QUOTE PARSER] Found title attributes: \"\(title)\"")
                return .title(title)
            }
            if string.contains("@") {
                let title = string.components(separatedBy: "@")[0]
                logger.log("[QUOTE PARSER] Found title attributes (non-quote): \"\(title)\"")
                return .title(String(title.dropFirst()))
            }
            return .title(String(string.dropFirst()))
        } else if string.first == " " {
            let pattern = /name=\"([^\"]+)\"(?: date=\"([^\"]+)\")?(?: post=(\d+))?/
            if let match = string.firstMatch(of: pattern) {
                let metadata = QuoteMetadata(
                    name: String(match.output.1),
                    date: match.output.2.map(String.init),
                    postId: match.output.3.flatMap { Int($0) }
                )
                logger.log("[QUOTE PARSER] Found metadata attributes: \"\(metadata.name)\" + \"\(metadata.date ?? "none")\" + \"\(metadata.postId ?? -1)\"")
                return .metadata(metadata)
            } else {
                fatalError("[QUOTE PARSER] Unrecognized pattern")
            }
        } else {
            return nil
        }
    }

    func parseQuote(from scanner: Scanner, attributes: String? = nil) -> TopicType {
        currentTag = .quote
        
        var results: [TopicType] = []
        let attributes = parseQuoteAttributes(attributes)
        
        while !scanner.isAtEnd {
            logger.log("[QUOTE] New iteration: \(self.printRemaining(scanner))")
            
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
                    logger.log("[QUOTE] Found quote (metadata mode)")
                    let types = parse(with: scanner)
                    results.append(.quote(types, attributes))
                } else if scanner.scanString("[quote=\"" + title + "\"]") != nil {
                    // TODO: Is this even working?
                    logger.log("[QUOTE] Found quote (title mode)")
                    let types = parse(with: scanner)
                    results.append(.quote(types, attributes))
                } else if scanner.scanString("[/quote]") != nil {
                    logger.log("[QUOTE] Found end of quote (had attributes)")
                    break
                } else {
                    logger.log("[QUOTE] Found no quote tag >>> \(self.printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                }
            } else {
                if scanner.scanString("[quote]") != nil {
                    // TODO: Can it actually find it since it's consumed in parse(with:)?
                    logger.log("[QUOTE] Found quote (plain mode)")
                    let types = parse(with: scanner)
                    results.append(.quote(types, attributes))
                } else if scanner.scanString("[/quote]") != nil {
                    logger.log("[QUOTE] Found end of quote (had no attributes)")
                    break
                } else {
                    logger.log("[QUOTE] Found no quote tag >>> \(self.printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                }
            }
        }
        
        logger.log("[QUOTE] Finished with \(results.count) results")
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
    
    func parseAttachment(from scanner: Scanner, attributes: String) -> TopicType {
        let attachmentId = parseAttachmentAttributes(attributes)
        return .attachment(attachmentId)
    }

    // MARK: - Spoiler

    func parseSpoilerAttributes(_ string: String?) -> String? {
        guard let string else {
            logger.log("[SPOILER PARSER] Found no attributes")
            return nil
        }
        
        let pattern = /=(?:"([^"]+)"|([^\]]+))/
        if let match = string.firstMatch(of: pattern) {
            if let output1 = match.output.1 {
                logger.log("[SPOILER PARSER] Found title: \(output1)")
                return String(output1)
            } else if let output2 = match.output.2 {
                logger.log("[SPOILER PARSER] Found title: \(output2)")
                return String(output2)
            } else {
                fatalError("[SPOILER PARSER] Unrecognized pattern")
            }
        } else {
            logger.log("[SPOILER PARSER] Found no attributes")
            return nil
        }
    }

    func parseSpoiler(from scanner: Scanner, attributes: String? = nil) -> TopicType {
        currentTag = .spoiler
        
        var results: [TopicType] = []
        let attributes = parseSpoilerAttributes(attributes)
        
        while !scanner.isAtEnd {
            if let attributes {
                if scanner.scanString("[spoiler=\"\(attributes)\"]") != nil {
                    logger.log("[SPOILER] Found spoiler tag (title mode, with quotes) >>> \(self.printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                } else if scanner.scanString("[spoiler=\(attributes)]") != nil {
                    logger.log("[SPOILER] Found spoiler tag (title mode, no quotes) >>> \(self.printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                } else if scanner.scanString("[/spoiler]") != nil {
                    logger.log("[SPOILER] Found end of spoiler (had attributes)")
                    break
                } else {
                    logger.log("[SPOILER] No more spoiler tag >>> \(self.printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                }
            } else {
                if scanner.scanString("[spoiler]") != nil {
                    logger.log("[SPOILER] Found spoiler tag (plain mode)")
                    let types = parse(with: scanner)
                    results.append(.spoiler(types, nil, nil))
                } else if scanner.scanString("[/spoiler]") != nil {
                    logger.log("[SPOILER] Found end of spoiler (had no attributes)")
                    break
                } else {
                    logger.log("[SPOILER] No more spoiler tag >>> \(self.printRemaining(scanner))")
                    let types = parse(with: scanner)
                    results.append(contentsOf: types)
                }
            }
        }
        
        logger.log("[SPOILER] Finished with \(results.count)")
        return .spoiler(results, attributes, nil)
    }

    // MARK: - List
    
    func parseList(from scanner: Scanner, listType: ListType) -> TopicType {
        defer { listCount -= 1 }
        currentTag = .list
        listCount += 1
        
        var results: [TopicType] = []
        
        while !scanner.isAtEnd {
            if scanner.scanString("[*]") != nil {
                logger.log("[LIST] Found [*] tag")
                let types = parse(with: scanner)
                results.append(.list(types, listType))
            } else if scanner.scanString("[list]") != nil {
                logger.log("[LIST] Found nested bullet list")
                let list = parseList(from: scanner, listType: .bullet)
                results.append(list)
            } else if scanner.scanString("[list=1]") != nil {
                logger.log("[LIST] Found nested numeric list")
                let list = parseList(from: scanner, listType: .numeric)
                results.append(list)
            } else if scanner.scanString("[list=I]") != nil {
                logger.log("[LIST] Found nested roman upper list")
                let list = parseList(from: scanner, listType: .roman)
                results.append(list)
            } else if scanner.scanString("[list=i]") != nil {
                logger.log("[LIST] Found nested roman lower list")
                let list = parseList(from: scanner, listType: .roman)
                results.append(list)
            } else if scanner.scanString("[list=A]") != nil {
                logger.log("[LIST] Found nested roman A list")
                let list = parseList(from: scanner, listType: .roman)
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
        
        logger.log("[LIST] Finished with \(results.count) results")
        return .list(results, listType)
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
            "list=1",
            "list=I",
            "list=A",
            "list=i",
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
            "hide",
            "/hide",
            "offtop",
            "/offtop",
            "cur",
            "/cur",
            "mod",
            "/mod",
            "ex",
            "/ex",
            "img",
            "/img",
            "attachment"
        ]

        // Define tags directly in the regex pattern
        let pattern = /\[([a-zA-Z\/]+)([^\[\]]*)\]/
        
        for match in string.matches(of: pattern) {
            let tag = String(match.output.1)

            guard validTags.contains(tag) else {
                logger.log("[VALIDATOR] Non-valid tag: \(tag)")
                continue
            }
            
            logger.log("[VALIDATOR] String: \"\(string.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: ""))\" -> Tag: \(tag)")
            
            // Extract attributes string, if present
            let attributes = String(match.output.2)
            
            // Find the starting index of the match
            let index = string.distance(from: string.startIndex, to: match.range.lowerBound)
            
            if !attributes.isEmpty {
                logger.log("[VALIDATOR] Returning with attributes")
                return (tag: "[\(tag)\(attributes)]", attributes: attributes, index: index)
            } else {
                return (tag: "[\(tag)]", attributes: nil, index: index)
            }
        }
        
        logger.log("[VALIDATOR] Found no more matches")
        return nil
    }
}
