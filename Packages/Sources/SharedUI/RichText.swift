//
//  RichText.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 12.11.2024.
//

import SwiftUI
import RichTextKit

public struct RichText: View {
    
    public let text: NSAttributedString
    public let font: Font?
    public let foregroundStyle: Color?
    public let configuration: (any RichTextViewComponent) -> Void
    
    public init(
        text: NSAttributedString,
        font: Font? = nil,
        foregroundStyle: Color? = nil,
        configuration: @escaping (any RichTextViewComponent) -> Void = { _ in }
    ) {
        self.text = text
        self.font = font
        self.foregroundStyle = foregroundStyle
        self.configuration = configuration
    }
    
    public var body: some View {
        RichTextEditor(text: .constant(text), context: .init()) {
            ($0 as? UITextView)?.backgroundColor = .clear
            ($0 as? UITextView)?.isEditable = false
            ($0 as? UITextView)?.isScrollEnabled = false
            
            if let font {
                ($0 as? UITextView)?.font = UIFont.preferredFont(from: font)
            }
            
            if let foregroundStyle {
                ($0 as? UITextView)?.textColor = UIColor(foregroundStyle)
            }
            
            configuration($0)
        }
    }
}

private extension UIFont {
    static func preferredFont(from font: Font) -> UIFont {
        let uiFont: UIFont
        
        switch font {
        case .largeTitle:
            uiFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title:
            uiFont = UIFont.preferredFont(forTextStyle: .title1)
        case .title2:
            uiFont = UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            uiFont = UIFont.preferredFont(forTextStyle: .title3)
        case .headline:
            uiFont = UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:
            uiFont = UIFont.preferredFont(forTextStyle: .subheadline)
        case .callout:
            uiFont = UIFont.preferredFont(forTextStyle: .callout)
        case .caption:
            uiFont = UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2:
            uiFont = UIFont.preferredFont(forTextStyle: .caption2)
        case .footnote:
            uiFont = UIFont.preferredFont(forTextStyle: .footnote)
        case .body:
            fallthrough
        default:
            uiFont = UIFont.preferredFont(forTextStyle: .body)
        }
        
        return uiFont
    }
}
