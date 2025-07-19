//
//  TopicRow.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 26.05.2025.
//

import SwiftUI
import SFSafeSymbols
import RichTextKit

public struct TopicRow: View {
    
    @Environment(\.tintColor) private var tintColor
    
    public let title: String
    public let date: Date
    public let username: String
    public let isClosed: Bool
    public let isUnread: Bool
    public let onAction: (_ unreadTapped: Bool) -> Void
    
    public init(
        title: String,
        date: Date,
        username: String,
        isClosed: Bool,
        isUnread: Bool,
        onAction: @escaping (_ unreadTapped: Bool) -> Void
    ) {
        self.title = title
        self.date = date
        self.username = username
        self.isClosed = isClosed
        self.isUnread = isUnread
        self.onAction = onAction
    }
    
    public var body: some View {
        Button {
            onAction(false)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(date.formattedDate(), bundle: .module)
                        .font(.caption)
                        .foregroundStyle(Color(.Labels.teritary))
                    
                    RichText(
                        text: AttributedString(title),
                        isSelectable: false,
                        font: .body,
                        foregroundStyle: Color(.Labels.primary)
                    )
                    
                    HStack(spacing: 4) {
                        Image(systemSymbol: .personCircle)
                            .font(.caption)
                            .foregroundStyle(Color(.Labels.secondary))
                        
                        RichText(
                            text: AttributedString(username),
                            isSelectable: false,
                            font: .caption,
                            foregroundStyle: Color(.Labels.secondary)
                        )
                    }
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 0) {
                    if isClosed {
                        Image(systemSymbol: .lock)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color(.Labels.secondary))
                            .padding(.trailing, isUnread ? -2 : 12)
                    }
                    
                    if isUnread {
                        Button {
                            onAction(true)
                        } label: {
                            Image(systemSymbol: .circleFill)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 10, height: 10)
                                .foregroundStyle(tintColor)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: 42, maxHeight: .infinity)
                    }
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

private extension Date {
    func formattedDate() -> LocalizedStringKey {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if Calendar.current.isDateInToday(self) {
            return LocalizedStringKey("Today, \(formatter.string(from: self))")
        } else if Calendar.current.isDateInYesterday(self) {
            return LocalizedStringKey("Yesterday, \(formatter.string(from: self))")
        } else {
            formatter.dateFormat = "dd.MM.yy, HH:mm"
            return LocalizedStringKey(formatter.string(from: self))
        }
    }
}

#Preview {
    List {
        TopicRow(
            title: "Обсуждение клиента",
            date: .now,
            username: "qwerty",
            isClosed: false,
            isUnread: true,
            onAction: { if $0 { print("Unread tapped") } }
        )
        
        TopicRow(
            title: "ForPDA [iOS]",
            date: .now,
            username: "subvertd",
            isClosed: false,
            isUnread: false,
            onAction: { if $0 { print("Unread tapped") } }
        )
        
        TopicRow(
            title: "За особые достижения отмечены",
            date: .now,
            username: "asdf",
            isClosed: true,
            isUnread: false,
            onAction: { if $0 { print("Unread tapped") } }
        )
        
        TopicRow(
            title: "Что нового было, пока вас не было?",
            date: .now,
            username: "123456789",
            isClosed: true,
            isUnread: true,
            onAction: { if $0 { print("Unread tapped") } }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

