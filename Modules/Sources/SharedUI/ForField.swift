//
//  ForField.swift
//  ForPDA
//
//  Created by Xialtal on 25.11.25.
//

import SwiftUI

public struct ForField<T: Hashable>: View {
    
    // MARK: - Properties
    
    @Environment(\.tintColor) private var tintColor
    @FocusState.Binding var focus: T?
    
    var content: Binding<String>
    let placeholder: LocalizedStringResource
    let focusEqual: T
    let characterLimit: Int?
    let minHeight: CGFloat?
    var selection: Binding<NSRange?>
    
    // MARK: - Init
    
    @available(*, deprecated, message: "Use init with Binding<NSRange?>")
    public init(
        content: Binding<String>,
        placeholder: LocalizedStringResource,
        focusEqual: T,
        focus: FocusState<T?>.Binding,
        characterLimit: Int? = nil,
        minHeight: CGFloat? = nil,
    ) {
        self.content = content
        self.placeholder = placeholder
        self.focusEqual = focusEqual
        self.characterLimit = characterLimit
        self.minHeight = minHeight
        
        self.selection = .constant(nil)
        
        self._focus = focus
    }
    
    public init(
        content: Binding<String>,
        placeholder: LocalizedStringResource,
        focusEqual: T,
        focus: FocusState<T?>.Binding,
        characterLimit: Int? = nil,
        minHeight: CGFloat? = nil,
        selection: Binding<NSRange?>
    ) {
        self.content = content
        self.placeholder = placeholder
        self.focusEqual = focusEqual
        self.characterLimit = characterLimit
        self.minHeight = minHeight
        self.selection = selection
        
        self._focus = focus
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            SelectableTextView(
                content: content,
                selection: selection,
                placeholder: placeholder,
                characterLimit: characterLimit
            )
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 12)
        .focused($focus, equals: focusEqual)
        .foregroundStyle(Color(.Labels.primary))
        .frame(minHeight: minHeight, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: isLiquidGlass ? 28 : 14)
                .fill(Color(.Background.teritary))
        }
        .overlay {
            RoundedRectangle(cornerRadius: isLiquidGlass ? 28 : 14)
                .stroke($focus.wrappedValue == focusEqual ? tintColor : Color(.Separator.primary), lineWidth: 1)
        }
        .onTapGesture {
            focus = focusEqual
        }
    }
}

// MARK: - Selectable Text View

private struct SelectableTextView: UIViewRepresentable {
    @Binding var content: String
    @Binding var selection: NSRange?
    let placeholder: LocalizedStringResource
    let characterLimit: Int?
    
    static let placeholderColor = UIColor.lightGray
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.text = content.isEmpty ? String(localized: placeholder) : content
        view.textColor = content.isEmpty ? Self.placeholderColor : UIColor.label
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .zero
        view.isScrollEnabled = false
        
        view.font = UIFont.preferredFont(forTextStyle: .body)
        
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.textColor != Self.placeholderColor, uiView.text != content {
            uiView.text = content
        }
        
        // when range (selection binding) has been changed in external place
        if let externalSelection = selection, uiView.selectedRange != externalSelection {
            uiView.selectedRange = externalSelection
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let dimensions = content.boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
            context: nil
        )
        return CGSize(width: width, height: ceil(dimensions.height))
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(
            content: $content,
            selection: $selection,
            characterLimit: characterLimit,
            placeholder: placeholder
        )
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        var content: Binding<String>
        var selection: Binding<NSRange?>
        let characterLimit: Int?
        let placeholder: LocalizedStringResource
        
        init(
            content: Binding<String>,
            selection: Binding<NSRange?>,
            characterLimit: Int?,
            placeholder: LocalizedStringResource
        ) {
            self.content = content
            self.selection = selection
            self.characterLimit = characterLimit
            self.placeholder = placeholder
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText: String) -> Bool {
            if let characterLimit = characterLimit {
                return textView.text.count + replacementText.count <= characterLimit
            }
            return true
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            selection.wrappedValue = textView.selectedRange
        }
        
        func textViewDidChange(_ textView: UITextView) {
            content.wrappedValue = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == placeholderColor {
                textView.text = nil
                textView.textColor = UIColor.label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = String(localized: placeholder)
                textView.textColor = placeholderColor
            }
        }
        
        func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            // init selection, cause until user not enter something, it always nil.
            if selection.wrappedValue == nil {
                selection.wrappedValue = NSMakeRange(0, 0)
            }
            return true
        }
    }
}
