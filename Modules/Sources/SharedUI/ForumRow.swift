//
//  TopicRow.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 26.05.2025.
//

import SwiftUI
import SFSafeSymbols
import RichTextKit

public struct ForumRow: View {
    
    @Environment(\.tintColor) private var tintColor
    
    public let title: String
    public let isUnread: Bool
    public let onAction: () -> Void
    
    public init(
        title: String,
        isUnread: Bool,
        onAction: @escaping () -> Void
    ) {
        self.title = title
        self.isUnread = isUnread
        self.onAction = onAction
    }
    
    public var body: some View {
        Button {
            onAction()
        } label: {
            HStack(spacing: 10) {
                RichText(
                    text: AttributedString(title),
                    isSelectable: false,
                    font: .body,
                    foregroundStyle: Color(.Labels.primary)
                )
                
                Spacer(minLength: 0)
                
                if isUnread {
                    Image(systemSymbol: .circleFill)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(tintColor)
                        .frame(maxWidth: 42, maxHeight: .infinity)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
        .buttonStyle(.plain)
        .frame(minHeight: 60)
    }
}

#Preview {
    List {
        ForumRow(
            title: "4PDA - работа сайта",
            isUnread: true,
            onAction: {}
        )
        
        ForumRow(
            title: "Пожелания",
            isUnread: false,
            onAction: {}
        )
        
        ForumRow(
            title: "iOS - Программы",
            isUnread: false,
            onAction: {}
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
