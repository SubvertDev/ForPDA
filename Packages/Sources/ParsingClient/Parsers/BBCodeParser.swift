//
//  BBCodeParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.09.2024.
//

import UIKit
import ZMarkupParser

public final class BBCodeParser {
    
    public static func parse(_ text: String?, fontStyle: UIFont.TextStyle = .body) -> NSAttributedString? {
        guard let inputText = text else { return nil }
        var text = inputText
        
        text = text.replacingOccurrences(of: "\n", with: "<br>") // New line / line break
        text = text.replacingOccurrences(of: "\\[b\\](.*?)\\[\\/b\\]", with: "<b>$1</b>", options: .regularExpression) // Bold
        text = text.replacingOccurrences(of: "\\[i\\](.*?)\\[\\/i\\]", with: "<i>$1</i>", options: .regularExpression) // Italic
        text = text.replacingOccurrences(of: "\\[s\\](.*?)\\[\\/s\\]", with: "<s>$1</s>", options: .regularExpression) // Strikethrough
        text = text.replacingOccurrences(of: "\\[u\\](.*?)\\[\\/u\\]", with: "<u>$1</u>", options: .regularExpression) // Underline
        text = text.replacingOccurrences(of: "\\[color=(.*?)\\](.*?)\\[\\/color\\]", with: "<font color=\"$1\">$2</font>", options: .regularExpression) // Text color
        text = text.replacingOccurrences(of: "\\[size=(.*?)\\](.*?)\\[\\/size\\]", with: "<span style=\"font-size:$1\">$2</span>", options: .regularExpression) // Text size
        text = text.replacingOccurrences(of: "\\[background=(.*?)\\](.*?)\\[\\/background\\]", with: "<span style=\"background-color:$1\">$2</span>", options: .regularExpression) // Text background
        text = text.replacingOccurrences(of: "\\[font=\"(.*?)\"\\](.*?)\\[\\/font\\]", with: "<span style=\"font-family:$1\">$2</span>", options: .regularExpression) // Text font
        text = text.replacingOccurrences(of: "\\[url\\](.*?)\\[\\/url\\]", with: "<a href=\"$1\">$1</a>", options: .regularExpression) // URL links without text
        text = text.replacingOccurrences(of: "\\[url=\"(.*?)\"\\](.*?)\\[\\/url\\]", with: "<a href=\"$1\">$2</a>", options: .regularExpression) // URL links with text
                
        let parser = ZHTMLParserBuilder.initWithDefault()
            .set(rootStyle: MarkupStyle(font: MarkupStyleFont(.preferredFont(forTextStyle: fontStyle))))
            .add(ExtendHTMLTagStyleAttribute(styleName: "font-size", render: { value in
                switch Int(value)! {
                case 1: return MarkupStyle(font: MarkupStyleFont(.preferredFont(forTextStyle: .caption2)))
                case 2: return MarkupStyle(font: MarkupStyleFont(.preferredFont(forTextStyle: .footnote)))
                case 3: return MarkupStyle(font: MarkupStyleFont(.preferredFont(forTextStyle: .body)))
                case 4: return MarkupStyle(font: MarkupStyleFont(.preferredFont(forTextStyle: .title3)))
                case 5: return MarkupStyle(font: MarkupStyleFont(.preferredFont(forTextStyle: .title2)))
                case 6: return MarkupStyle(font: MarkupStyleFont(.preferredFont(forTextStyle: .title1)))
                case 7: return MarkupStyle(font: MarkupStyleFont(.preferredFont(forTextStyle: .largeTitle)))
                default: return nil
                }
            }))
            .add(ExtendHTMLTagStyleAttribute(styleName: "font-family", render: { value in
                if let familyName = UIFont.familyNames.first(where: { $0.lowercased().contains(value) }) {
                    return MarkupStyle(font: MarkupStyleFont(familyName: .familyNames([familyName])))
                } else {
                    return nil
                }
            }))
            .build()
        
        let renderedText = parser.render(text)
        
        // Making text color adapt to dark mode
        let mutableString = NSMutableAttributedString(attributedString: renderedText)
        let fullRange = NSRange(location: 0, length: mutableString.length)
        mutableString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            if attributes[.foregroundColor] == nil {
                mutableString.addAttribute(.foregroundColor, value: UIColor.label, range: range)
            }
        }
        
        return NSAttributedString(attributedString: mutableString)
    }
}
