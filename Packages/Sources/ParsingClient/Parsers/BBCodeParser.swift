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
        
        text = text.replacingOccurrences(of: "\\[b\\](.*?)\\[\\/b\\]", with: "<b>$1</b>", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\[i\\](.*?)\\[\\/i\\]", with: "<i>$1</i>", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\[s\\](.*?)\\[\\/s\\]", with: "<s>$1</s>", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\[u\\](.*?)\\[\\/u\\]", with: "<u>$1</u>", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\[color=(.*?)\\](.*?)\\[\\/color\\]", with: "<font color=\"$1\">$2</font>", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\[size=(.*?)\\](.*?)\\[\\/size\\]", with: "<span style=\"font-size:$1\">$2</span>", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\[background=(.*?)\\](.*?)\\[\\/background\\]", with: "<span style=\"background-color:$1\">$2</span>", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\[font=\"(.*?)\"\\](.*?)\\[\\/font\\]", with: "<span style=\"font-family:$1\">$2</span>", options: .regularExpression)
                
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
        
        return parser.render(text)
    }
}