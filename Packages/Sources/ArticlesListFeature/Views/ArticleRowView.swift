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
    
    let article: ArticlePreview
    let store: StoreOf<ArticlesListFeature>
    let isShort: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            LazyImage(url: article.imageUrl) { state in
                Group {
                    if let image = state.image {
                        Color.clear
                            .aspectRatio(21/9, contentMode: .fit)
                            .overlay { image.resizable().scaledToFill()}
                            .clipped()
                            .contentShape(Rectangle())
                    } else {
                        Color.Background.teritary
                            .aspectRatio(21/9, contentMode: .fit)
                    }
                }
                .skeleton(with: state.isLoading, shape: .rectangle)
            }
            .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(article.authorName)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(Color.Labels.secondary)
                    .padding(.bottom, 4)
                
                Text(article.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)
                
                Rectangle()
                    .foregroundStyle(Color.Separator.primary)
                    .frame(height: 0.33)
                    .padding(.bottom, 17)
                
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
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(Color.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Separator.primary, lineWidth: 0.67)
        )
        .pdaContextMenu(article: article, store: store)
    }
}
