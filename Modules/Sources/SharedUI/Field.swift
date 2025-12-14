//
//  Field.swift
//  ForPDA
//
//  Created by Xialtal on 14.06.25.
//

import SwiftUI

public struct Field: View {
    
    @FocusState.Binding var isFocused: Bool
    
    let text: Binding<String>
    let description: String
    let guideText: String
    var isEditor = false
    
    public init(
        text: Binding<String>,
        description: String,
        guideText: String,
        isEditor: Bool = false,
        isFocused: FocusState<Bool>.Binding
    ) {
        self.text = text
        self.description = description
        self.guideText = guideText
        self.isEditor = isEditor
        
        self._isFocused = isFocused
    }
    
    public var body: some View {
        VStack {
            Group {
                TextField(text: text, axis: .vertical) {
                    Text(guideText)
                        .font(.body)
                        .foregroundStyle(Color(.quaternaryLabel))
                }
                .focused($isFocused)
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Color(.Labels.primary))
                .frame(minHeight: isEditor ? 144 : nil, alignment: .top)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: isLiquidGlass ? 28 : 14)
                    .fill(Color(.Background.teritary))
                    .onTapGesture {
                        isFocused = true
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: isLiquidGlass ? 28 : 14)
                    .strokeBorder(Color(.Separator.primary))
            }
            
            if !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.teritary))
                    .textCase(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
            }
        }
        .animation(.default, value: false)
        .onAppear {
            isFocused = true
        }
    }
}
