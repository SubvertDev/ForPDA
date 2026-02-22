//
//  EditReasonView.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 20.07.2025.
//

import SwiftUI

struct EditReasonView: View {
    
    // MARK: - Properties
    
    @Environment(\.tintColor) private var tintColor
    
    let id: Int
    @Binding var text: String
    @Binding var isEditingReasonEnabled: Bool
    @Binding var isShowMarkEnabled: Bool
    @FocusState.Binding var focusedField: Int?
    let canShowShowMark: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Text("Editing reason", bundle: .module)
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Toggle(String(""), isOn: $isEditingReasonEnabled)
                    .labelsHidden()
                    .tint(tintColor)
            }
            .padding(.horizontal, 2)
            
            if isEditingReasonEnabled {
                Field(
                    id: id,
                    text: $text,
                    placeholder: "Введите причину",
                    isEditor: true,
                    focusedField: $focusedField
                )
                
                if canShowShowMark {
                    Toggle(isOn: $isShowMarkEnabled) {
                        Text("Show mark", bundle: .module)
                            .font(.subheadline)
                            .foregroundStyle(Color(.Labels.secondary))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .toggleStyle(CheckBox())
                    .tint(tintColor)
                    .padding(6)
                }
            }
        }
        .animation(.default, value: isEditingReasonEnabled)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var text = ""
    @Previewable @State var isEditingReasonEnabled = false
    @Previewable @State var isShowMarkEnabled = false
    @Previewable @FocusState var focusedField: Int?
    
    EditReasonView(
        id: 0,
        text: $text,
        isEditingReasonEnabled: $isEditingReasonEnabled,
        isShowMarkEnabled: $isShowMarkEnabled,
        focusedField: $focusedField,
        canShowShowMark: true
    )
    .padding(.horizontal, 16)
}
