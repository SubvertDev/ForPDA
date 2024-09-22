//
//  ArticleRowView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import SkeletonUI
import NukeUI

public struct ArticleRowView: View {
    
    @Namespace private var namespace
    @Environment(\.tintColor) private var tintColor
    
    public let state: State
    public let rowType: RowType
    public let contextMenuActions: ContextMenuActions
    
    private var isShort: Bool {
        return rowType == .short
    }
    
    private var id: String {
        return String(state.id)
    }
    
    public init(
        state: State,
        rowType: RowType,
        contextMenuActions: ContextMenuActions
    ) {
        self.state = state
        self.rowType = rowType
        self.contextMenuActions = contextMenuActions
    }
    
    public var body: some View {
        Group {
            switch rowType {
            case .normal:
                NormalRow()
            case .short:
                ShortRow()
            }
        }
//        .transition(.opacity)
//        .animation(.smooth, value: isShort)
        .pdaContextMenu(
            title: state.title,
            authorName: state.authorName,
            contextMenuActions: contextMenuActions
        )
    }
    
    // MARK: - Normal Row
    
    @ViewBuilder
    private func NormalRow() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ArticleImage()
                .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 0) {
                Description()
                
                Separator()
                    .padding(.bottom, 17)
                
                Footer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(
            Color.Background.primary
//                .matchedGeometryEffect(id: "background\(id)", in: namespace)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Separator.primary, lineWidth: isShort ? 0 : 0.67)
        )
    }
    
    // MARK: - Short Row
    
    @ViewBuilder
    private func ShortRow() -> some View {
        VStack(spacing: 0) {
            Separator()
                .padding(.bottom, 12)
            
            HStack(alignment: .top, spacing: 12) {
                ArticleImage()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(width: 90, height: 90)
                
                VStack(spacing: 0) {
                    Description()
                    
                    Footer()
                }
            }
        }
        .background(
            Color.Background.primary
//                .matchedGeometryEffect(id: "background\(id)", in: namespace)
        )
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func ArticleImage() -> some View {
        LazyImage(url: state.imageUrl) { state in
            Group {
                if let image = state.image {
                    Color.clear
                        .overlay { image.resizable().scaledToFill() }
                        .clipped()
                        .contentShape(Rectangle())
//                        .matchedGeometryEffect(id: "image\(id)", in: namespace)
                } else {
                    Color.Background.teritary
                        .frame(maxHeight: .infinity)
//                        .matchedGeometryEffect(id: "image\(id)", in: namespace)
                }
            }
            .skeleton(with: state.isLoading, shape: .rectangle)
            .aspectRatio(isShort ? 1 : 21/9, contentMode: .fit)
        }
        .clipShape(
            .rect(topLeadingRadius: 16, bottomLeadingRadius: isShort ? 16 : 0, bottomTrailingRadius: isShort ? 16 : 0, topTrailingRadius: 16)
        )
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(state.authorName)
                .font(isShort ? .caption : .footnote)
                .fontWeight(.regular)
                .foregroundStyle(Color.Labels.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            
            Text(state.title)
                .font(isShort ? .callout : .title3)
                .fontWeight(.semibold)
                .lineLimit(nil)
                .foregroundStyle(Color.Labels.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isShort ? 8 : 12)
        }
//        .matchedGeometryEffect(id: "description\(id)", in: namespace)
    }
    
    // MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 3) {
                Image(systemSymbol: .bubbleRight)
                Text(String(state.commentsAmount))
            }
            .font(.caption)
            .foregroundStyle(Color.Labels.teritary)
            .padding(.trailing, 6)
            
            Text(String("·"))
                .font(.caption)
                .foregroundStyle(Color.Labels.quaternary)
                .padding(.trailing, 6)
            
            Text(state.formattedDate)
                .font(.caption)
                .foregroundStyle(Color.Labels.quaternary)
            
            Spacer()
            
            ContextMenu()
        }
//        .matchedGeometryEffect(id: "footer\(id)", in: namespace)
    }
    
    // MARK: - Separator
    
    @ViewBuilder
    private func Separator() -> some View {
        Rectangle()
            .foregroundStyle(Color.Separator.primary)
            .frame(height: 0.33)
//            .matchedGeometryEffect(id: "separator\(id)", in: namespace)
    }
    
    // MARK: - Context Menu
        
    @ViewBuilder
    private func ContextMenu() -> some View {
        Menu {
            MenuButtons(
                title: state.title,
                authorName: state.authorName,
                contextMenuActions: contextMenuActions
            )
        } label: {
            Image(systemSymbol: .ellipsis)
                .font(.body)
                .foregroundStyle(Color.Labels.teritary)
                .padding(.horizontal, isShort ? 8 : 16) // Padding for tap area
                .padding(.vertical, isShort ? 11 : 22)
        }
        .frame(width: 19, height: 22)
    }
}

// MARK: - State Model

public extension ArticleRowView {
    struct State {
        public let id: Int
        public let title: String
        public let authorName: String
        public let imageUrl: URL
        public let commentsAmount: Int
        public let date: Date
        
        public init(id: Int, title: String, authorName: String, imageUrl: URL, commentsAmount: Int, date: Date) {
            self.id = id
            self.title = title
            self.authorName = authorName
            self.imageUrl = imageUrl
            self.commentsAmount = commentsAmount
            self.date = date
        }
        
        public var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Row Type

public extension ArticleRowView {
    enum RowType: String, Sendable, Equatable, Codable {
        case normal
        case short
        
        public static func toggle(from state: RowType) -> RowType {
            if state == RowType.normal {
                return RowType.short
            } else {
                return RowType.normal
            }
        }
    }
}
