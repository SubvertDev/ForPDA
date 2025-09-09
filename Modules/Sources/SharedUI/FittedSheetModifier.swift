//
//  FittedSheetModifier.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.02.2025.
//

import SwiftUI

public extension View {
    func fittedSheet<Item: Identifiable, Content: View>(
        item binding: Binding<Item?>,
        embedIntoNavStack: Bool = false,
        onDismiss: @escaping () -> Void = {},
        content: @escaping (Item) -> Content
    ) -> some View {
        modifier(
            FittedSheetModifier(
                item: binding,
                embedIntoNavStack: embedIntoNavStack,
                onDismiss: onDismiss,
                itemContent: content
            )
        )
    }
}

private struct FittedSheetModifier<Item: Identifiable, ItemContent: View>: ViewModifier {
    @Binding var item: Item?
    let embedIntoNavStack: Bool
    let onDismiss: () -> Void
    let itemContent: (Item) -> ItemContent
    
    @State private var size: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $item, onDismiss: onDismiss) { item in
                Group {
                    if embedIntoNavStack {
                        NavigationStack {
                            itemContent(item)
                                .storeSize(in: $size, embedded: embedIntoNavStack)
                        }
                    } else {
                        itemContent(item)
                            .storeSize(in: $size, embedded: embedIntoNavStack)
                    }
                }
                .presentationDetents([.height(size.height)])
                .presentationDragIndicator(.visible)
            }
    }
}

private extension View {
    func getSize(callback: @Sendable @escaping (CGSize) -> Void) -> some View {
        overlay {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: proxy.size)
            }
        }
        .onPreferenceChange(SizePreferenceKey.self, perform: callback)
    }
    
    func storeSize(in binding: Binding<CGSize>, embedded: Bool) -> some View {
        // TODO: Is it actually 70/60? Does drag indicator counts?
        let additionalHeight: CGFloat = embedded ? (isLiquidGlass ? 70 : 60) : 0
        return getSize {
            binding.wrappedValue = CGSize(
                width: $0.width,
                height: $0.height + additionalHeight
            )
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
