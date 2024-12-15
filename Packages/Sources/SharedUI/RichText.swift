//
//  RichText.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 12.11.2024.
//

import SwiftUI
import RichTextKit

public typealias URLTapHandler = (URL) -> Void

public struct RichText: View {
    
    public let text: NSAttributedString
    public let font: Font?
    public let foregroundStyle: Color?
    public var onUrlTap: URLTapHandler?
    public let configuration: (any RichTextViewComponent) -> Void
    @State private var delegate: TextViewDelegate
    
    // TODO: Deprecated
    public init(
        text: NSAttributedString,
        font: Font? = nil,
        foregroundStyle: Color? = nil,
        captureUrlTaps: Bool = false,
        onUrlTap: URLTapHandler? = nil,
        configuration: @escaping (any RichTextViewComponent) -> Void = { _ in }
    ) {
        self.text = text
        self.font = font
        self.foregroundStyle = foregroundStyle
        self.onUrlTap = onUrlTap
        self.configuration = configuration
        
        self.delegate = TextViewDelegate(onUrlTap: onUrlTap)
    }
    
    public init(
        text: AttributedString,
        font: Font? = nil,
        foregroundStyle: Color? = nil,
        captureUrlTaps: Bool = false,
        onUrlTap: URLTapHandler? = nil,
        configuration: @escaping (any RichTextViewComponent) -> Void = { _ in }
    ) {
        self.text = NSAttributedString(text)
        self.font = font
        self.foregroundStyle = foregroundStyle
        self.onUrlTap = onUrlTap
        self.configuration = configuration
        
        self.delegate = TextViewDelegate(onUrlTap: onUrlTap)
    }
    
    public var body: some View {
        RichTextEditor(text: .constant(text), context: .init(), textKit2Enabled: false) {
            let textView = $0 as? UITextView
            textView?.backgroundColor = .clear
            textView?.isEditable = false
            textView?.isScrollEnabled = false
            
            if let font {
                textView?.font = UIFont.preferredFont(from: font)
            }
            
            if let foregroundStyle {
                textView?.textColor = UIColor(foregroundStyle)
            }
            
            if onUrlTap != nil {
                textView?.delegate = delegate
            }
            
            configuration($0)
        }
    }
}

private extension UIFont {
    static func preferredFont(from font: Font) -> UIFont {
        switch font {
        case .largeTitle:   return UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title:        return UIFont.preferredFont(forTextStyle: .title1)
        case .title2:       return UIFont.preferredFont(forTextStyle: .title2)
        case .title3:       return UIFont.preferredFont(forTextStyle: .title3)
        case .headline:     return UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:  return UIFont.preferredFont(forTextStyle: .subheadline)
        case .callout:      return UIFont.preferredFont(forTextStyle: .callout)
        case .caption:      return UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2:     return UIFont.preferredFont(forTextStyle: .caption2)
        case .footnote:     return UIFont.preferredFont(forTextStyle: .footnote)
        case .body:         fallthrough
        default:            return UIFont.preferredFont(forTextStyle: .body)
        }
    }
}

private class TextViewDelegate: NSObject, UITextViewDelegate {
    
    private let onUrlTap: URLTapHandler?
    
    init(onUrlTap: URLTapHandler?) {
        self.onUrlTap = onUrlTap
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("Intercepted URL tap: \(URL)") // TODO: Remove after tests
        if let onUrlTap {
            onUrlTap(URL)
            return false
        } else {
            return true
        }
    }
}
