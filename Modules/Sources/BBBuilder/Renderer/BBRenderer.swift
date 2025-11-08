import UIKit
import SwiftUI
import SharedUI
import Models
import CustomDump
import ComposableArchitecture
import AnalyticsClient

public final class BBRenderer {
    
    public static nonisolated(unsafe) let defaultAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.defaultBBFont,
        .foregroundColor: UIColor(resource: .Labels.primary)
    ]
    
    private let baseAttributes: [NSAttributedString.Key: Any]
    
    public init(baseAttributes: [NSAttributedString.Key: Any]? = nil) {
        var attributes = baseAttributes ?? BBRenderer.defaultAttributes
        
        // Setting custom font disables dynamic foregroundColor
        if attributes.count == 1,
           attributes[.font] != nil,
           attributes[.foregroundColor] == nil {
            attributes[.foregroundColor] = UIColor(resource: .Labels.primary)
        }
        
        self.baseAttributes = attributes
    }
    
    public func render(text: String) -> NSAttributedString {
        let elements = BBParser.parse(text: text)
        let resultNodes = elements.map { $0.render(withAttributes: baseAttributes) }
        let joinedNode = resultNodes.joined()
        guard case let .text(text) = joinedNode else { fatalError() }
        return text
    }
}

private extension BBNode {
    func render(withAttributes attributes: [NSAttributedString.Key: Any]) -> BBContainerNode {
        guard let currentFont = attributes[NSAttributedString.Key.font] as? UIFont else {
            fatalError("Missing font attribute in \(attributes)")
        }
        
        switch self {
        case .text(let text):
            let text = text.decodeHTMLEntities()
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            return .text(attributedText)

        case .bold(let children):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.font] = currentFont.boldFont()
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .italic(let children):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.font] = currentFont.italicFont()
            return children.map { $0.render(withAttributes: newAttributes) }.joined()

        case .underline(let children):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .strikethrough(let children):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .sup(let children):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.baselineOffset] = 5
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .sub(let children):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.baselineOffset] = -5
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .size(let size, let children):
            var newAttributes = attributes
            let currentFont = newAttributes[NSAttributedString.Key.font] as! UIFont
            if currentFont.fontName == UIFont.systemFont(ofSize: currentFont.pointSize).fontName {
                newAttributes[NSAttributedString.Key.font] = UIFont
                    .preferredFont(forBBCodeSize: size)
                    .addingSymbolicTraits(of: currentFont)
            } else {
                newAttributes[NSAttributedString.Key.font] = currentFont
                    .withSize(UIFont.preferredFont(forBBCodeSize: size).pointSize)
                    .addingSymbolicTraits(of: currentFont)
            }
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .color(let color, let children):
            var newAttributes = attributes
            if let dynamicColor = ForumColors(rawValue: color.lowercased())?.hexColor {
                newAttributes[NSAttributedString.Key.foregroundColor] = UIColor(dynamicTuple: dynamicColor)
            } else {
                newAttributes[NSAttributedString.Key.foregroundColor] = UIColor(hex: color)
            }
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .background(let color, let children):
            var newAttributes = attributes
            let dynamicColor = ForumColors(rawValue: color.lowercased())?.hexColor ?? ("FFFFFF", "000000") // TODO: !!!
            newAttributes[NSAttributedString.Key.backgroundColor] = UIColor(dynamicTuple: dynamicColor)
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .font(let name, let children):
            var newAttributes = attributes
            if let customFont = SharedUIFontFamily.allCustomFonts.first(where: { $0.name == name }) {
                newAttributes[NSAttributedString.Key.font] = customFont.font(size: currentFont.pointSize)
                     // .addingSymbolicTraits(of: currentFont)
            } else {
                print("[ОШИБКА] НЕ ПОЛУЧИЛОСЬ НАЙТИ ФОНТ \(name), ИСПОЛЬЗУЮ СТАНДАРТНЫЙ")
                newAttributes[NSAttributedString.Key.font] = UIFont
                    .defaultBBFont
                    .addingSymbolicTraits(of: currentFont)
            }
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .url(let url, let children):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.link] = url
            newAttributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .anchor(let children):
            return children.map { $0.render(withAttributes: attributes) }.joined() // TODO: !
            
        case .offtop(let children):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.font] = UIFont
                .preferredFont(forTextStyle: .caption2)
                .addingSymbolicTraits(of: currentFont)
            newAttributes[NSAttributedString.Key.foregroundColor] = UIColor(Color(.Labels.quaternary))
            return children.map { $0.render(withAttributes: newAttributes) }.joined()
            
        case .center(let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .center(nodes)
            
        case .left(let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .left(nodes)
            
        case .right(let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .right(nodes)
            
        case .justify(let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .justify(nodes)
            
        case .spoiler(let attribute, let children):
            let attributedString = attribute.map { BBRenderer(baseAttributes: attributes).render(text: $0) }
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .spoiler(attributedString, nodes)
            
        case .quote(let attribute, let children):
            let attributedString = attribute.map { BBRenderer(baseAttributes: attributes).render(text: $0) }
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .quote(attributedString, nodes)
            
        case .list(let type, let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .list(type, nodes)

        case .code(let attribute, let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .code(attribute.map { NSAttributedString(string: $0) }, nodes)

        case .hide(let attribute, let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .hide(attribute.map { NSAttributedString(string: $0) }, nodes)

        case .cur(let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .cur(nodes)

        case .mod(let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .mod(nodes)

        case .ex(let children):
            let nodes = children.map { $0.render(withAttributes: attributes) }
            return .ex(nodes)
            
        case .snapback(let postId):
            return .snapback(NSAttributedString(string: postId))
            
        case .mergetime(let time):
            return .mergetime(NSAttributedString(string: time, attributes: attributes))
            
        case .img(let url):
            return .img(NSAttributedString(string: url))
            
        case .attachment(let string):
            return .attachment(NSAttributedString(string: string))
            
        case .smile(let smile):
            return .smile(NSAttributedString(string: smile))
        }
    }
}

public extension UIFont {
    static func preferredFont(forBBCodeSize size: Int?) -> UIFont {
        switch size {
        case 1: return UIFont.preferredFont(forTextStyle: .caption2)
        case 2: return UIFont.preferredFont(forTextStyle: .footnote)
        case 3: return UIFont.preferredFont(forTextStyle: .callout)
        case 4: return UIFont.preferredFont(forTextStyle: .body)
        case 5: return UIFont.preferredFont(forTextStyle: .title3)
        case 6: return UIFont.preferredFont(forTextStyle: .title2)
        case 7: return UIFont.preferredFont(forTextStyle: .title1)
        default: return UIFont.preferredFont(forTextStyle: .callout)
        }
    }
    
    static var defaultBBFont: UIFont {
        return preferredFont(forBBCodeSize: 3) // TODO: Actually, default size is more like ~1.5
    }
}

extension UIColor {
    convenience init(dynamicTuple: (String, String)) {
        self.init(dynamicProvider: { traits in
            let hex = traits.userInterfaceStyle == .dark ? dynamicTuple.1 : dynamicTuple.0
            return UIColor(hex: hex) ?? .label
        })
    }
}

extension UIColor {
    convenience init?(hex: String) {
        let hex = hex
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "\"", with: "")
        
        guard hex.count == 6, let hexNumber = UInt32(hex, radix: 16) else {
            return nil
        }
        
        let r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hexNumber & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIColor {
    convenience init(
        light lightModeColor: @escaping @autoclosure () -> UIColor,
        dark darkModeColor: @escaping @autoclosure () -> UIColor
     ) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light:
                return lightModeColor()
            case .dark:
                return darkModeColor()
            case .unspecified:
                return lightModeColor()
            @unknown default:
                return lightModeColor()
            }
        }
    }
}

enum ForumColors: String, CaseIterable {
    // Breaks color on light/dark mode change
//    case black
//    case white
    case skyblue
    case royalblue
    case blue
    case darkblue
    case orange
    case orangered
    case crimson
    case red
    case darkred
    case green
    case limegreen
    case seagreen
    case deeppink
    case tomato
    case coral
    case purple
    case indigo
    case burlywood
    case sandybrown
    case sienna
    case chocolate
    case teal
    case silver
    
    // Others
    case grey
    case alicewhite
    case antiquewhite
    case aqua
    case aquamarine
    case azure
    case beige
    case bisque
    case blanchedalmond
//    case blue
    case blueviolet
    case brown
//    case burlywood
    case cadetblue
    case chartreuse
//    case chocolate
//    case coral
    case cornflowerblue
    case cornsilk
//    case crimson
    case cyan
//    case darkblue
    case darkcyan
    case darkgoldenrod
    case darkgray
    case darkgreen
    case darkkhaki
    case darkmagenta
    case darkolivegreen
    case darkorange
    case darkorchid
//    case darkred
    case darksalmon
    case darkseagreen
    case darkslateblue
    case darkslategray
    case darkturquoise
    case darkviolet
//    case deeppink
    case deepskyblue
    case dimgray
    case dodgerblue
    case firebrick
    case floralwhite
    case forestgreen
    case fuchsia
    case gainsboro
    case ghostwhite
    case gold
    case goldenrod
    case gray
//    case green
    case greenyellow
    case honeydew
    case hotpink
    case indianred
//    case indigo
    case ivory
    case khaki
    case lavender
    case lavenderblush
    case lawngreen
    case lemonchiffon
    case lightblue
    case lightcoral
    case lightcyan
    case lightgoldenrodyellow
    case lightgreen
    case lightgrey
    case lightpink
    case lightsalmon
    case lightseagreen
    case lightskyblue
    case lightslategray
    case lightsteelblue
    case linen
    case magenta
    case maroon
    case mediumaquamarine
    case mediumblue
    case mediumorchid
    case mediumpurple
    case mediumseagreen
    case mediumslateblue
    case mediumspringgreen
    case mediumturquoise
    case mediumvioletred
    case midnightblue
    case mintcream
    case mistyrose
    case moccasin
    case navajowhite
    case navy
    case oldlace
    case olive
    case olivedrab
//    case orange
//    case orangered
    case orchid
    case palegoldenrod
    case palegreen
    
    public var hexColor: (String, String) {
        switch self {
            // Breaks color on light/dark mode change
//        case .black:        return ("000000", "909090")
//        case .white:        return ("FFFFFF", "FFFFFF")
        case .skyblue:      return ("87CEEB", "87CEEB")
        case .royalblue:    return ("4169E1", "4169E1")
        case .blue:         return ("0000FF", "0000FF")
        case .darkblue:     return ("00008B", "00008B")
        case .orange:       return ("FFA500", "FFA500")
        case .orangered:    return ("FF4500", "FF4500")
        case .crimson:      return ("DC143C", "DC143C")
        case .red:          return ("FF0000", "FF0000")
        case .darkred:      return ("8B0000", "CB4040")
        case .green:        return ("008001", "20A020")
        case .limegreen:    return ("33CD32", "32CD32")
        case .seagreen:     return ("2E8B58", "2E8B57")
        case .deeppink:     return ("FF1393", "FF1493")
        case .tomato:       return ("FF6348", "FF6347")
        case .coral:        return ("FF7F50", "FF7F50")
        case .purple:       return ("800080", "A020A0")
        case .indigo:       return ("4B0082", "6B20A2")
        case .burlywood:    return ("DEB887", "DEB887")
        case .sandybrown:   return ("F4A361", "F4A460")
        case .sienna:       return ("A0522D", "A0522D")
        case .chocolate:    return ("D3691E", "D2691E")
        case .teal:         return ("008080", "008080")
        case .silver:       return ("C0C0C0", "C0C0C0")
            
            // Others
        case .grey:         return ("808080", "808080")
        case .alicewhite: return ("F0F8FF", "F0F8FF")
        case .antiquewhite: return ("FAEBD7", "FAEBD7")
        case .aqua: return ("00FFFF", "00FFFF")
        case .aquamarine: return ("7FFFD4", "7FFFD4")
        case .azure: return ("F0FFFF", "F0FFFF")
        case .beige: return ("F5F5DC", "F5F5DC")
        case .bisque: return ("FFE4C4", "FFE4C4")
        case .blanchedalmond: return ("FFEBCD", "FFEBCD")
//        case .blue: return ("0000FF", "0000FF")
        case .blueviolet: return ("8A2BE2", "8A2BE2")
        case .brown: return ("A52A2A", "A52A2A")
//        case .burlywood: return ("DEB887", "DEB887")
        case .cadetblue: return ("5F9EA0", "5F9EA0")
        case .chartreuse: return ("7FFF00", "7FFF00")
//        case .chocolate: return ("D2691E", "D2691E")
//        case .coral: return ("FF7F50", "FF7F50")
        case .cornflowerblue: return ("6495ED", "6495ED")
        case .cornsilk: return ("FFF8DC", "FFF8DC")
//        case .crimson: return ("DC143C", "DC143C")
        case .cyan: return ("00FFFF", "00FFFF")
//        case .darkblue: return ("00008B", "00008B")
        case .darkcyan: return ("008B8B", "008B8B")
        case .darkgoldenrod: return ("B8860B", "B8860B")
        case .darkgray: return ("A9A9A9", "A9A9A9")
        case .darkgreen: return ("006400", "006400")
        case .darkkhaki: return ("BDB76B", "BDB76B")
        case .darkmagenta: return ("8B008B", "8B008B")
        case .darkolivegreen: return ("556B2F", "556B2F")
        case .darkorange: return ("FF8C00", "FF8C00")
        case .darkorchid: return ("9932CC", "9932CC")
//        case .darkred: return ("8B0000", "8B0000")
        case .darksalmon: return ("E9967A", "E9967A")
        case .darkseagreen: return ("8FBC8F", "8FBC8F")
        case .darkslateblue: return ("483D8B", "483D8B")
        case .darkslategray: return ("2F4F4F", "2F4F4F")
        case .darkturquoise: return ("00CED1", "00CED1")
        case .darkviolet: return ("9400D3", "9400D3")
//        case .deeppink: return ("FF1493", "FF1493")
        case .deepskyblue: return ("00BFFF", "00BFFF")
        case .dimgray: return ("696969", "696969")
        case .dodgerblue: return ("1E90FF", "1E90FF")
        case .firebrick: return ("B22222", "B22222")
        case .floralwhite: return ("FFFAF0", "FFFAF0")
        case .forestgreen: return ("228B22", "228B22")
        case .fuchsia: return ("FF00FF", "FF00FF")
        case .gainsboro: return ("DCDCDC", "DCDCDC")
        case .ghostwhite: return ("F8F8FF", "F8F8FF")
        case .gold: return ("FFD700", "FFD700")
        case .goldenrod: return ("DAA520", "DAA520")
        case .gray: return ("808080", "808080")
//        case .green: return ("008000", "008000")
        case .greenyellow: return ("ADFF2F", "ADFF2F")
        case .honeydew: return ("F0FFF0", "F0FFF0")
        case .hotpink: return ("FF69B4", "FF69B4")
        case .indianred: return ("CD5C5C", "CD5C5C")
//        case .indigo: return ("4B0082", "4B0082")
        case .ivory: return ("FFFFF0", "FFFFF0")
        case .khaki: return ("F0E68C", "F0E68C")
        case .lavender: return ("E6E6FA", "E6E6FA")
        case .lavenderblush: return ("FFF0F5", "FFF0F5")
        case .lawngreen: return ("7CFC00", "7CFC00")
        case .lemonchiffon: return ("FFFACD", "FFFACD")
        case .lightblue: return ("ADD8E6", "ADD8E6")
        case .lightcoral: return ("F08080", "F08080")
        case .lightcyan: return ("E0FFFF", "E0FFFF")
        case .lightgoldenrodyellow: return ("FAFAD2", "FAFAD2")
        case .lightgreen: return ("90EE90", "90EE90")
        case .lightgrey: return ("D3D3D3", "D3D3D3")
        case .lightpink: return ("FFB6C1", "FFB6C1")
        case .lightsalmon: return ("FFA07A", "FFA07A")
        case .lightseagreen: return ("20B2AA", "20B2AA")
        case .lightskyblue: return ("87CEFA", "87CEFA")
        case .lightslategray: return ("778899", "778899")
        case .lightsteelblue: return ("B0C4DE", "B0C4DE")
        case .linen: return ("FAF0E6", "FAF0E6")
        case .magenta: return ("FF00FF", "FF00FF")
        case .maroon: return ("800000", "800000")
        case .mediumaquamarine: return ("66CDAA", "66CDAA")
        case .mediumblue: return ("0000CD", "0000CD")
        case .mediumorchid: return ("BA55D3", "BA55D3")
        case .mediumpurple: return ("9370D8", "9370D8")
        case .mediumseagreen: return ("3CB371", "3CB371")
        case .mediumslateblue: return ("7B68EE", "7B68EE")
        case .mediumspringgreen: return ("00FA9A", "00FA9A")
        case .mediumturquoise: return ("48D1CC", "48D1CC")
        case .mediumvioletred: return ("C71585", "C71585")
        case .midnightblue: return ("191970", "191970")
        case .mintcream: return ("F5FFFA", "F5FFFA")
        case .mistyrose: return ("FFE4E1", "FFE4E1")
        case .moccasin: return ("FFE4B5", "FFE4B5")
        case .navajowhite: return ("FFDEAD", "FFDEAD")
        case .navy: return ("000080", "000080")
        case .oldlace: return ("FDF5E6", "FDF5E6")
        case .olive: return ("808000", "808000")
        case .olivedrab: return ("688E23", "688E23")
//        case .orange: return ("FFA500", "FFA500")
//        case .orangered: return ("FF4500", "FF4500")
        case .orchid: return ("DA70D6", "DA70D6")
        case .palegoldenrod: return ("EEE8AA", "EEE8AA")
        case .palegreen: return ("98FB98", "98FB98")
        }
    }
}

extension Array where Element: NSAttributedString {
    func joined() -> NSAttributedString {
        let result = NSMutableAttributedString()
        for element in self {
            result.append(element)
        }
        return result
    }
}

public extension Array where Element == BBContainerNode {
    func joined() -> BBContainerNode {
        let result = NSMutableAttributedString()
        for element in self {
            switch element {
            case .text(let string):
                result.append(string)
                
            case .spoiler(let attributed, let children):
                result.append(NSAttributedString(string: "[spoiler"))
                if let attributed {
                    result.append(NSAttributedString(string: "="))
                    result.append(attributed)
                }
                result.append(NSAttributedString(string: "]"))
                if case let .text(string) = children.joined() {
                    result.append(string)
                }
                result.append(NSAttributedString(string: "[/spoiler]"))
                
            case .quote(let attributed, let children):
                result.append(NSAttributedString(string: "[quote"))
                if let attributed {
                    result.append(NSAttributedString(string: "="))
                    result.append(attributed)
                }
                result.append(NSAttributedString(string: "]"))
                if case let .text(string) = children.joined() {
                    result.append(string)
                }
                result.append(NSAttributedString(string: "[/quote]"))
                
            case .code(let attributed, let children):
                result.append(NSAttributedString(string: "[code"))
                if let attributed {
                    result.append(NSAttributedString(string: "="))
                    result.append(attributed)
                }
                result.append(NSAttributedString(string: "]"))
                if case let .text(string) = children.joined() {
                    result.append(string)
                }
                result.append(NSAttributedString(string: "[/code]"))
                
            default:
                break
            }
        }
        return .text(result)
    }
}

extension UIFont {
    func boldFont() -> UIFont? {
        return addingSymbolicTraits(.traitBold) ?? self
    }

    func italicFont() -> UIFont? {
        return addingSymbolicTraits(.traitItalic) ?? self
    }
    
    func addingSymbolicTraits(of font: UIFont) -> UIFont? {
        addingSymbolicTraits(font.fontDescriptor.symbolicTraits) ?? font
    }

    func addingSymbolicTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        let newTraits = fontDescriptor.symbolicTraits.union(traits)
        guard let descriptor = fontDescriptor.withSymbolicTraits(newTraits) else {
            @Dependency(\.logger) var logger
            logger.error("Failed to find symbolic trait \(traits.rawValue) for \(self.fontName), returning self")
            return nil
        }

        return UIFont(descriptor: descriptor, size: 0)
    }
}
