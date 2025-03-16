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
    
    @State public var text: NSAttributedString
    public let isSelectable: Bool
    public let font: Font?
    public let foregroundStyle: Color?
    public var onUrlTap: URLTapHandler?
    public let configuration: (any RichTextViewComponent) -> Void
    @State private var delegate: TextViewDelegate
    @State private var refreshId = UUID()
    
    // TODO: Deprecated
    public init(
        text: NSAttributedString,
        isSelectable: Bool = true,
        font: Font? = nil,
        foregroundStyle: Color? = nil,
        captureUrlTaps: Bool = false,
        onUrlTap: URLTapHandler? = nil,
        configuration: @escaping (any RichTextViewComponent) -> Void = { _ in }
    ) {
        self.text = text
        self.isSelectable = isSelectable
        self.font = font
        self.foregroundStyle = foregroundStyle
        self.onUrlTap = onUrlTap
        self.configuration = configuration
        
        self.delegate = TextViewDelegate(onUrlTap: onUrlTap)
    }
    
    public init(
        text: AttributedString,
        isSelectable: Bool = true,
        font: Font? = nil,
        foregroundStyle: Color? = nil,
        captureUrlTaps: Bool = false,
        onUrlTap: URLTapHandler? = nil,
        configuration: @escaping (any RichTextViewComponent) -> Void = { _ in }
    ) {
        self.text = NSAttributedString(text)
        self.isSelectable = isSelectable
        self.font = font
        self.foregroundStyle = foregroundStyle
        self.onUrlTap = onUrlTap
        self.configuration = configuration
        
        self.delegate = TextViewDelegate(onUrlTap: onUrlTap)
        
        let attributedString = NSAttributedString(text)
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.enumerateAttribute(.attachment, in: range, options: []) { value, effectiveRange, _ in
            guard let foundAttachment = value as? AsyncTextAttachment else {
                return
            }
            foundAttachment.delegate = delegate
//            print("Found attachment: \(foundAttachment)")
        }
    }
    
    public var body: some View {
        RichTextEditor(text: $text, context: RichTextContext(), textKit2Enabled: false) {
            let textView = $0 as? UITextView
            textView?.backgroundColor = .clear
            textView?.isEditable = false
            textView?.isSelectable = isSelectable
            textView?.isScrollEnabled = false
            textView?.textDragInteraction?.isEnabled = false
            
            if let font {
                textView?.font = UIFont.preferredFont(from: font)
            }
            
            if let foregroundStyle {
                textView?.textColor = UIColor(foregroundStyle)
            }
            
//            textView?.linkTextAttributes = [
//                .font: UIFont.preferredFont(forTextStyle: .callout), // TODO: BBFont?
//                .foregroundColor: UIColor(resource: .Labels.primary),
//                .underlineColor: UIColor(resource: .Theme.primary),
//                .underlineStyle: NSUnderlineStyle.single.rawValue
//            ]
            
            if onUrlTap != nil {
                textView?.delegate = delegate
            }
            delegate.textView = textView
            delegate.setRefresh($refreshId)
            
            configuration($0)
        }
        .id(refreshId)
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

private class TextViewDelegate: NSObject, UITextViewDelegate, @preconcurrency AsyncTextAttachmentDelegate {
    
    @Binding var refreshId: UUID
    private let onUrlTap: URLTapHandler?
//    @Binding var text: NSAttributedString?
    weak var textView: UITextView?
    
    init(refreshId: Binding<UUID> = .constant(UUID()), onUrlTap: URLTapHandler?) {
        self._refreshId = refreshId
        self.onUrlTap = onUrlTap
    }
    
    func setRefresh(_ refreshId: Binding<UUID>) {
        self._refreshId = refreshId
    }
    
//    init(text: Binding<NSAttributedString>, onUrlTap: URLTapHandler?) {
//        self._text = text
//        self.onUrlTap = onUrlTap
//    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("Intercepted URL tap: \(URL)") // TODO: Remove after tests
        if let onUrlTap {
            onUrlTap(URL)
            return false
        } else {
            return true
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let postIdString = textAttachment.image?.accessibilityHint,
            let postId = Int(postIdString) {
            print("Snapback postId = \(postId)")
            return false
        } else {
            print("[ERROR] Couldn't extract postId from SnapbackImage")
            return false
        }
    }
    
    func textAttachmentDidLoadImage(textAttachment: AsyncTextAttachment, displaySizeChanged: Bool) {
        print("Delegate called \(displaySizeChanged) \(textAttachment)")
        refreshId = UUID()
    }
}
