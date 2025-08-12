//
//  Field.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 20.07.2025.
//

import SwiftUI

struct Field: View {
    
    // MARK: - Properties
    
    let id: Int
    let text: Binding<String>
    let placeholder: String
    var isEditor: Bool
    
    @FocusState.Binding var focusedField: Int?
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Group {
                TextField(text: text, axis: .vertical) {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(Color(.quaternaryLabel))
                }
                .focused($focusedField, equals: id)
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Color(.Labels.primary))
                .frame(minHeight: isEditor ? 144 : nil, alignment: .top)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.Background.teritary))
                    .onTapGesture {
                        focusedField = nil
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(.Separator.primary))
            }
        }
        .animation(.default, value: false)
    }
}
