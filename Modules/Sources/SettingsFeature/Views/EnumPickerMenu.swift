//
//  EnumPickerMenu.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.10.2025.
//

import SwiftUI
import ComposableArchitecture

struct EnumPickerMenu<Selection: Hashable & CaseIterable, Content: View, Label: View>: View {
    @Binding var selection: Selection
    let content: (Selection) -> Content
    let label: () -> Label

    var body: some View {
        Menu {
            Picker(String(""), selection: $selection) {
                ForEach(Array(Selection.allCases), id: \.self) { item in
                    content(item)
                }
            }
            .pickerStyle(.inline)
        } label: {
            WithPerceptionTracking {
                label()
            }
        }
    }
}
