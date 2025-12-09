//
//  ForField.swift
//  ForPDA
//
//  Created by Xialtal on 25.11.25.
//

import SwiftUI

public struct ForField<T: Hashable>: View {
    @Environment(\.tintColor) private var tintColor
    @FocusState.Binding var focus: T?
    
    var content: Binding<String>
    let placeholder: LocalizedStringResource
    let focusEqual: T
    let characterLimit: Int?
    
    public init(
        content: Binding<String>,
        placeholder: LocalizedStringResource,
        focusEqual: T,
        focus: FocusState<T?>.Binding,
        characterLimit: Int? = nil
    ) {
        self.content = content
        self.placeholder = placeholder
        self.focusEqual = focusEqual
        self.characterLimit = characterLimit
        
        self._focus = focus
    }
    
    public var body: some View {
        Group {
            TextField(text: content, axis: .vertical) {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.quaternary))
            }
            .onChange(of: content.wrappedValue) { newValue in
                if let limit = characterLimit, newValue.count > limit {
                    content.wrappedValue = String(newValue.prefix(limit))
                }
            }
            .focused($focus, equals: focusEqual)
            .font(.body)
            .foregroundStyle(Color(.Labels.primary))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: nil, alignment: .top)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 12)
        .background {
            if #available(iOS 26, *) {
                ConcentricRectangle()
                    .fill(Color(.Background.teritary))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.Background.teritary))
            }
        }
        .overlay {
            if #available(iOS 26, *) {
                ConcentricRectangle()
                    .stroke($focus.wrappedValue == focusEqual ? tintColor : Color(.Separator.primary), lineWidth: 1)
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .stroke($focus.wrappedValue == focusEqual ? tintColor : Color(.Separator.primary), lineWidth: 1)
            }
        }
    }
}
