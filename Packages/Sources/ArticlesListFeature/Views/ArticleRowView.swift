//
//  ArticleRowView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture
import SkeletonUI
import NukeUI
import Models
import SharedUI

struct ArticleRowView: View {
    
    @Namespace private var namespace
    
    let article: ArticlePreview
    let store: StoreOf<ArticlesListFeature>
    let rowType: ArticlesListRowType
    
    private var isShort: Bool {
        return rowType == .short
    }
    
    private var id: String {
        return String(article.id)
    }
    
    var body: some View {
        Group {
            switch rowType {
            case .normal:
                NormalRow()
            case .short:
                ShortRow()
            }
        }
        .pdaContextMenu(article: article, store: store)
        .transition(.opacity)
        .animation(.smooth, value: isShort)
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
        .background(Color.Background.primary)
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
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func ArticleImage() -> some View {
        LazyImage(url: article.imageUrl) { state in
            Group {
                if let image = state.image {
                    Color.clear
                        .overlay { image.resizable().scaledToFill() }
                        .clipped()
                        .contentShape(Rectangle())
                        .matchedGeometryEffect(id: "image\(id)", in: namespace)
                } else {
                    Color.Background.teritary
                        .frame(maxHeight: .infinity)
                        .matchedGeometryEffect(id: "image\(id)", in: namespace)
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
            Text(article.authorName)
                .font(isShort ? .caption : .footnote)
                .fontWeight(.regular)
                .foregroundStyle(Color.Labels.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            
            Text(article.title)
                .font(isShort ? .callout : .title3)
                .fontWeight(.semibold)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isShort ? 8 : 12)
        }
        .matchedGeometryEffect(id: "description\(id)", in: namespace)
    }
    
    // MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 3) {
                Image(systemSymbol: .bubbleRight)
                Text(String(article.commentsAmount))
            }
            .font(.caption)
            .foregroundStyle(Color.Labels.teritary)
            .padding(.trailing, 6)
            
            Text(String("·"))
                .font(.caption)
                .foregroundStyle(Color.Labels.quaternary)
                .padding(.trailing, 6)
            
            Text(article.formattedDate)
                .font(.caption)
                .foregroundStyle(Color.Labels.quaternary)
            
            Spacer()
            
            Menu {
                MenuButtons(
                    article: article,
                    shareAction: {
                        store.send(.cellMenuOpened(article, .shareLink))
                    },
                    copyAction: {
                        store.send(.cellMenuOpened(article, .copyLink))
                    },
                    openInBrowserAction: {
                        store.send(.cellMenuOpened(article, .openInBrowser))
                    },
                    reportAction: {
                        store.send(.cellMenuOpened(article, .report))
                    },
                    addToBookmarksAction: {
                        store.send(.cellMenuOpened(article, .addToBookmarks))
                    }
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
        .matchedGeometryEffect(id: "footer\(id)", in: namespace)
    }
    
    // MARK: - Separator
    
    @ViewBuilder
    private func Separator() -> some View {
        Rectangle()
            .foregroundStyle(Color.Separator.primary)
            .frame(height: 0.33)
            .matchedGeometryEffect(id: "separator\(id)", in: namespace)
    }
}
