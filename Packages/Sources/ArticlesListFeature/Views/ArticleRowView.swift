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
    
    @Namespace private var animationNamespace
    
    let article: ArticlePreview
    let store: StoreOf<ArticlesListFeature>
    let isShort: Bool
    
    private var id: String {
        return String(article.id)
    }
    
    var body: some View {
        Group {
            if isShort {
                ShortRow()
            } else {
                NormalRow()
            }
        }
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
                    .matchedGeometryEffect(id: "description\(id)", in: animationNamespace)
                
                Separator()
                    .padding(.bottom, 17)
                    .matchedGeometryEffect(id: "separator\(id)", in: animationNamespace)
                
                Footer()
                    .matchedGeometryEffect(id: "footer\(id)", in: animationNamespace)
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
        .pdaContextMenu(article: article, store: store)
    }
    
    // MARK: - Short Row
    
    @ViewBuilder
    private func ShortRow() -> some View {
        VStack(spacing: 0) {
            Separator()
                .padding(.bottom, 12)
                .matchedGeometryEffect(id: "separator\(id)", in: animationNamespace)
            
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    ArticleImage()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(width: 90, height: 90)
                    
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    Description()
                        .matchedGeometryEffect(id: "description\(id)", in: animationNamespace)
                    
                    Footer()
                        .matchedGeometryEffect(id: "footer\(id)", in: animationNamespace)
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
                } else {
                    Color.Background.teritary
                        .frame(maxHeight: .infinity)
                }
            }
            .skeleton(with: state.isLoading, shape: .rectangle)
            .aspectRatio(isShort ? 1 : 21/9, contentMode: .fit)
        }
        .clipShape(
            .rect(topLeadingRadius: 16, bottomLeadingRadius: isShort ? 16 : 0, bottomTrailingRadius: isShort ? 16 : 0, topTrailingRadius: 16)
        )
        .matchedGeometryEffect(id: "image\(id)", in: animationNamespace)
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
                        print("not implemented")
                    },
                    reportAction: {
                        store.send(.cellMenuOpened(article, .report))
                    },
                    addToBookmarksAction: {
                        print("not implemented")
                    }
                )
            } label: {
                Image(systemSymbol: .ellipsis)
                    .font(.body)
                    .foregroundStyle(Color.Labels.teritary)
                    .padding(.horizontal, 16) // Padding for tap area
                    .padding(.vertical, 22)
            }
            .frame(width: 19, height: 22)
        }
    }
    
    // MARK: - Separator
    
    @ViewBuilder
    private func Separator() -> some View {
        Rectangle()
            .foregroundStyle(Color.Separator.primary)
            .frame(height: 0.33)
    }
}
