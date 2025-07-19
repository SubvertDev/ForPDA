//
//  FittedSheetModifier.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.02.2025.
//

import SwiftUI

// TODO: Do I need it?

public extension View {
    func fittedSheet<Item: Identifiable, Content: View>(item binding: Binding<Item?>, onDismiss: @escaping () -> Void = {}, content: @escaping (Item) -> Content) -> some View {
        modifier(FittedSheetModifier(item: binding, onDismiss: onDismiss, itemContent: content))
    }
}

struct FittedSheetModifier<Item: Identifiable, ItemContent: View>: ViewModifier {
    @Binding var item: Item?
    let onDismiss: () -> Void
    let itemContent: (Item) -> ItemContent
    
    @State private var size: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $item, onDismiss: onDismiss) { item in
                itemContent(item)
                    .storeSize(in: $size)
                    .presentationDetents([.height(size.height)])
                    .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    func getSize(callback: @Sendable @escaping (CGSize) -> Void) -> some View {
        overlay {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: proxy.size)
            }
        }
        .onPreferenceChange(SizePreferenceKey.self, perform: callback)
    }
    
    func storeSize(in binding: Binding<CGSize>) -> some View {
        getSize { binding.wrappedValue = $0 }
    }
}

struct SizePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
